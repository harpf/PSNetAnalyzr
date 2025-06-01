
function Get-NANICDetails {
    <#
.SYNOPSIS
Returns detailed hardware and driver information of physical network adapters (local or remote).

.DESCRIPTION
Uses CIM and WMI to retrieve NIC details such as manufacturer, MAC address, driver version, and PCI ID.
Supports querying remote computers with error handling and optional structured logging.

.PARAMETER Name
Optional wildcard to filter NIC name.

.PARAMETER ComputerName
Remote computer name to query via CIM.

.PARAMETER Credential
Optional credentials for remote CIM session.

.PARAMETER CimSession
An existing CimSession to reuse for querying a remote system.

.PARAMETER LogFile
Optional path to a log file where results and errors will be structured and written.

.OUTPUTS
[pscustomobject]

.EXAMPLE
Get-NANICDetails

.EXAMPLE
Get-NANICDetails -Name "*Intel*"

.EXAMPLE
Get-NANICDetails -ComputerName "RemotePC"

.EXAMPLE
$cred = Get-Credential
Get-NANICDetails -ComputerName "RemotePC" -Credential $cred

.EXAMPLE
Get-NANICDetails -LogFile "C:\Logs\NIC_Report.txt"
#>

    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param (
        [Parameter(ParameterSetName = 'Local')]
        [Parameter(ParameterSetName = 'Remote')]
        [string]$Name,

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
                Write-Verbose "Creating new CIM session to $ComputerName..."
                if ($LogFile) { Write-NAHelperLog -Message "Creating new CIM session to $ComputerName" -Type Info -Path $LogFile }
                $CimSession = New-CimSession @cimParams
            }

            Write-Verbose "Querying NICs on remote computer '$ComputerName'..."
            if ($LogFile) { Write-NAHelperLog -Message "Querying NICs on remote computer '$ComputerName'" -Type Info -Path $LogFile }

            $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter -CimSession $CimSession |
            Where-Object {
                $_.PhysicalAdapter -eq $true -and $_.MACAddress -ne $null -and (!$Name -or $_.Name -like $Name)
            }

            $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver -CimSession $CimSession
        }
        else {
            Write-Verbose "Querying NICs on local computer..."
            if ($LogFile) { Write-NAHelperLog -Message "Querying NICs on local computer" -Type Info -Path $LogFile }

            $adapters = Get-CimInstance -ClassName Win32_NetworkAdapter |
            Where-Object {
                $_.PhysicalAdapter -eq $true -and $_.MACAddress -ne $null -and (!$Name -or $_.Name -like $Name)
            }

            $drivers = Get-CimInstance -ClassName Win32_PnPSignedDriver
        }

        $results = [System.Collections.Generic.List[object]]::new()

        foreach ($adapter in $adapters) {
            $driver = $drivers | Where-Object { $_.DeviceID -eq $adapter.PNPDeviceID }

            $pciInfo = if ($adapter.PNPDeviceID -match 'PCI\\VEN_(\w{4})&DEV_(\w{4})') {
                "VEN=$($matches[1]), DEV=$($matches[2])"
            }
            else {
                "N/A"
            }

            $obj = [pscustomobject]@{
                Name          = $adapter.Name
                Description   = $adapter.Description
                MACAddress    = $adapter.MACAddress
                Manufacturer  = $adapter.Manufacturer
                AdapterType   = $adapter.AdapterType
                DriverVersion = $driver.DriverVersion
                DriverDate    = $driver.DriverDate
                PNPDeviceID   = $adapter.PNPDeviceID
                PCIInfo       = $pciInfo
            }

            $obj.PSObject.TypeNames.Insert(0, 'NetzwerkToolkit.NICDetails')
            $results.Add($obj)

            if ($LogFile) {
                Write-NAHelperLog -Message "NIC: $($adapter.Name) | MAC: $($adapter.MACAddress) | Driver: $($driver.DriverVersion)" -Type Info -Path $LogFile
            }
        }

        return $results
    }
    catch {
        $errorMsg = "Failed to retrieve NIC details: $_"
        Write-Error $errorMsg
        if ($LogFile) { Write-NAHelperLog -Message $errorMsg -Type Error -Path $LogFile }
    }
}