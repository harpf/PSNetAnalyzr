function Get-NADataLinkMacTable {
<#
.SYNOPSIS
Retrieves the MAC address forwarding table (FDB) from an SNMP-capable switch using SNMP.

.DESCRIPTION
Uses snmpwalk (Net-SNMP) to query the Bridge-MIB (`dot1dTpFdbTable`, OID: 1.3.6.1.2.1.17.4.3.1).
Outputs a structured list of MAC addresses and the ports they are associated with.

.PARAMETER Target
IP address or hostname of the SNMP-enabled switch.

.PARAMETER Version
SNMP version (1, 2c, or 3).

.PARAMETER Community
SNMP community string (for SNMP v1/v2c).

.PARAMETER Username
Username for SNMPv3.

.PARAMETER AuthPassword
Authentication password for SNMPv3.

.PARAMETER PrivProtocol
Encryption protocol for SNMPv3 (AES or DES, optional).

.PARAMETER PrivPassword
Encryption password for SNMPv3 (optional).

.PARAMETER LogPath
Optional path to a log file.

.OUTPUTS
[pscustomobject] with MACAddress and Port.

.EXAMPLE
Get-NADataLinkMacTable -Target 192.168.1.1 -Version 2c -Community public
#>
    [CmdletBinding(DefaultParameterSetName = 'v2c')]
    param (
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [ValidateSet('1','2c','3')]
        [string]$Version,

        [Parameter(ParameterSetName = 'v1')]
        [Parameter(ParameterSetName = 'v2c')]
        [string]$Community = "public",

        [Parameter(ParameterSetName = 'v3', Mandatory)]
        [string]$Username,

        [Parameter(ParameterSetName = 'v3', Mandatory)]
        [string]$AuthPassword,

        [Parameter(ParameterSetName = 'v3')]
        [ValidateSet("DES","AES")]
        [string]$PrivProtocol,

        [Parameter(ParameterSetName = 'v3')]
        [string]$PrivPassword,

        [string]$LogPath
    )

    $baseOid = "1.3.6.1.2.1.17.4.3.1.2"  # dot1dTpFdbPort
    $tool = "snmpwalk.exe"
    $binPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Bin"
    $exePath = Join-Path $binPath $tool

    if (-not (Test-Path $exePath)) {
        throw "snmpwalk.exe not found at: $exePath"
    }

    $paramargs = @("-m", '""', "-v", $Version)

    switch ($Version) {
        '1' { $paramargs += @("-c", $Community, $Target, $baseOid) }
        '2c' { $paramargs += @("-c", $Community, $Target, $baseOid) }
        '3' {
            $level = if ($PrivProtocol -and $PrivPassword) { "authPriv" } else { "authNoPriv" }
            $paramargs += @(
                "-l", $level,
                "-u", $Username,
                "-a", "SHA",
                "-A", $AuthPassword
            )
            if ($level -eq "authPriv") {
                $paramargs += @("-x", $PrivProtocol, "-X", $PrivPassword)
            }
            $paramargs += @($Target, $baseOid)
        }
    }

    try {
        if ($LogPath) {
            Write-NAHelperLog -Message "Executing: $exePath $($paramargs -join ' ')" -Type Info -Path $LogPath
        }

        $output = & "$exePath" @args 2>&1

        if ($LogPath) {
            Write-NAHelperLog -Message "Raw output: $($output -join ' | ')" -Type Info -Path $LogPath
        }

        return $output |
            Where-Object { $_ -match '1\.3\.6\.1\.2\.1\.17\.4\.3\.1\.2\.' } |
            ForEach-Object {
                if ($_ -match '1\.3\.6\.1\.2\.1\.17\.4\.3\.1\.2\.(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)\.(\d+)\s*=\s*INTEGER:\s*(\d+)') {
                    $mac = '{0:X2}:{1:X2}:{2:X2}:{3:X2}:{4:X2}:{5:X2}' -f $matches[1..6]
                    $port = [int]$matches[7]
                    [pscustomobject]@{
                        MACAddress = $mac
                        Port       = $port
                    }
                }
            }
    }
    catch {
        if ($LogPath) {
            Write-NAHelperLog -Message "Error: $_" -Type Error -Path $LogPath
        }
        throw "Error while reading MAC address table: $_"
    }
}
