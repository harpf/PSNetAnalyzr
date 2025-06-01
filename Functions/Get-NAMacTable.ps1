function Get-NAMacTable {
    <#
.SYNOPSIS
Retrieves MAC address table information using Net-SNMP (snmpwalk/snmpget).

.DESCRIPTION
Supports SNMPv1, v2c and v3 to query a specific OID from a target device using Net-SNMP binaries.

.PARAMETER Target
The IP or hostname of the SNMP-enabled device.

.PARAMETER Community
The SNMP community string (for v1/v2c).

.PARAMETER Oid
The SNMP OID to query.

.PARAMETER Version
The SNMP version to use (1, 2c, or 3).

.PARAMETER Username
SNMPv3 username.

.PARAMETER AuthPassword
SNMPv3 authentication password.

.PARAMETER PrivProtocol
(Optional) SNMPv3 privacy protocol (e.g., AES, DES).

.PARAMETER PrivPassword
(Optional) SNMPv3 privacy password.

.PARAMETER Walk
If set, snmpwalk will be used; otherwise snmpget.

.PARAMETER LogPath
Optional path for a log file.

.OUTPUTS
[pscustomobject] with OID and Value pairs.

.EXAMPLE
Get-NAMacTable -Target "127.0.0.1" -Community "public" -Oid "1.3.6.1.2.1.1" -Version "2c" -Walk

.EXAMPLE
Get-NAMacTable -Target "127.0.0.1" -Username "user" -AuthPassword "pass" -Version "3" -Oid "1.3.6.1.2.1.1" -Walk
#>
    [CmdletBinding(DefaultParameterSetName = 'v2c')]
    param (
        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$Oid,

        [Parameter(Mandatory)]
        [ValidateSet('1', '2c', '3')]
        [string]$Version,

        [Parameter(ParameterSetName = 'v1')]
        [Parameter(ParameterSetName = 'v2c')]
        [string]$Community = "public",

        [Parameter(ParameterSetName = 'v3', Mandatory)]
        [string]$Username,

        [Parameter(ParameterSetName = 'v3', Mandatory)]
        [string]$AuthPassword,

        [Parameter(ParameterSetName = 'v3')]
        [ValidateSet("DES", "AES")]
        [string]$PrivProtocol,

        [Parameter(ParameterSetName = 'v3')]
        [string]$PrivPassword,

        [switch]$Walk,

        [string]$LogPath
    )

    if (-not $Walk -and $Oid -notmatch '\.0$') {
        Write-Warning "SNMP OID for snmpget should end with '.0'. Appending '.0' to OID."
        return $null
    }
    $tool = if ($Walk) { "snmpwalk.exe" } else { "snmpget.exe" }
    $binPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Bin"
    $exePath = Join-Path $binPath $tool

    if (-not (Test-Path $exePath)) {
        throw "Executable not found: $exePath"
    }

    $paramargs = @("-m", '""', "-v", $Version)

    switch ($Version) {
        '1' { $paramargs += @("-c", $Community, $Target, $Oid) }
        '2c' { $paramargs += @("-c", $Community, $Target, $Oid) }
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
            $paramargs += @($Target, $Oid)
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

        return $output | Where-Object { $_ -match "=" } | ForEach-Object {
            $line = $_ -replace '\s{2,}', ' '
            $parts = $line -split '\s*=\s*', 2
            if ($parts.Length -eq 2) {
                [pscustomobject]@{
                    OID   = $parts[0].Trim()
                    Value = $parts[1].Trim()
                }
            }
        }
    }
    catch {
        if ($LogPath) {
            Write-NAHelperLog -Message "Error occurred: $_" -Type Error -Path $LogPath
        }
        throw "SNMP query failed: $_"
    }
}