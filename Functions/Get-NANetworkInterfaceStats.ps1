function Get-NANetworkInterfaceStats {
<#
.SYNOPSIS
Displays statistics for all physical network interfaces, locally or remotely.

.DESCRIPTION
Retrieves network interface data using .NET (locally) or CIM (remotely via Get-CimInstance). 
Provides extended interface details such as name, status, speed, MAC address, and type.
Use the -Detailed switch (only local) for advanced statistics like traffic counters and DNS info.

.PARAMETER Name
Optional filter to limit results to interfaces matching a wildcard pattern.

.PARAMETER Detailed
Include extended statistics (only available for local queries).

.PARAMETER ComputerName
Specify a remote computer to query via CIM. If specified, local mode is disabled.

.PARAMETER Credential
Optional credentials for the remote CIM session.

.PARAMETER CimSession
An existing CimSession object for querying a remote system.

.PARAMETER LogFile
Optional path to write diagnostic output and errors.

.OUTPUTS
[pscustomobject] with NIC information.

.EXAMPLE
Get-NANetworkInterfaceStats

.EXAMPLE
Get-NANetworkInterfaceStats -Name "Ethernet*"

.EXAMPLE
Get-NANetworkInterfaceStats -Detailed

.EXAMPLE
Get-NANetworkInterfaceStats -ComputerName "RemotePC"

.EXAMPLE
$cred = Get-Credential
Get-NANetworkInterfaceStats -ComputerName "RemotePC" -Credential $cred

.EXAMPLE
$session = New-CimSession -ComputerName "RemotePC"
Get-NANetworkInterfaceStats -CimSession $session

.EXAMPLE
Get-NANetworkInterfaceStats -LogFile "C:\Logs\nic_stats.log"
#>

    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param (
        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'Remote')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Local')]
        [switch]$Detailed,

        [Parameter(Mandatory = $true, ParameterSetName = 'Remote')]
        [string]$ComputerName,

        [Parameter(ParameterSetName = 'Remote')]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(ParameterSetName = 'Remote')]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession,

        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'Remote')]
        [string]$LogFile
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq 'Remote') {
            if (-not $CimSession) {
                $cimParams = @{ ComputerName = $ComputerName }
                if ($Credential) { $cimParams.Credential = $Credential }
                Write-NAHelperLog -Message "Creating new CIM session to $ComputerName" -Type Info -Path $LogFile
                $CimSession = New-CimSession @cimParams
            }

            $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter -CimSession $CimSession |
                Where-Object {
                    $_.PhysicalAdapter -eq $true -and (!$Name -or $_.Name -like $Name)
                }

            foreach ($adapter in $adapters) {
                $obj = [PSCustomObject]@{
                    Name        = $adapter.Name
                    Description = $adapter.Description
                    Status      = $adapter.NetConnectionStatus
                    SpeedMbps   = [math]::Round($adapter.Speed / 1MB, 2)
                    MAC         = ($adapter.MACAddress -replace '(.{2})(?=.)','$1:')
                    Type        = $adapter.AdapterType
                    Source      = $ComputerName
                }
                $obj.PSObject.TypeNames.Insert(0, 'Selected.NetworkInterfaceStats')
                return $obj

                Write-NAHelperLog -Message "Queried NIC $($adapter.Name) on $ComputerName" -Type Info -Path $LogFile
            }
        }
        else {
            $nics = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
                Where-Object {
                    $_.NetworkInterfaceType -ne 'Loopback' -and (!$Name -or $_.Name -like $Name)
                }

            foreach ($nic in $nics) {
                $basic = [PSCustomObject]@{
                    Name        = $nic.Name
                    Description = $nic.Description
                    Status      = $nic.OperationalStatus
                    SpeedMbps   = [math]::Round($nic.Speed / 1MB, 2)
                    MAC         = ($nic.GetPhysicalAddress().ToString() -replace '(.{2})(?=.)','$1:')
                    Type        = $nic.NetworkInterfaceType
                    Source      = $env:COMPUTERNAME
                }

                if ($Detailed) {
                    $props = $nic.GetIPProperties()
                    $ipv4  = $nic.GetIPv4Statistics()

                    $details = [PSCustomObject]@{
                        MulticastSupport       = $nic.SupportsMulticast
                        ReceiveOnly            = $nic.IsReceiveOnly
                        BytesReceived          = $ipv4.BytesReceived
                        BytesSent              = $ipv4.BytesSent
                        UnicastPacketsReceived = $ipv4.UnicastPacketsReceived
                        GatewayAddresses       = $props.GatewayAddresses.AddressToString -join ', '
                        DNSAddresses           = $props.DnsAddresses.IPAddressToString -join ', '
                        DHCPServer             = $props.DhcpServerAddresses.IPAddressToString -join ', '
                    }

                    $basic | Add-Member -MemberType NoteProperty -Name "Details" -Value $details
                }

                $basic.PSObject.TypeNames.Insert(0, 'Selected.NetworkInterfaceStats')
                return $basic

                Write-NAHelperLog -Message "Queried NIC $($nic.Name) on local system" -Type Info -Path $LogFile
            }
        }
    }
    catch {
        $err = "Failed to retrieve NIC statistics: $_"
        Write-Error $err
        Write-NAHelperLog -Message $err -Type Error -Path $LogFile
    }
}
