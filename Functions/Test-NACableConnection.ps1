function Test-NACableConnection {
<#
.SYNOPSIS
Checks for physical link status of network interfaces using .NET.

.DESCRIPTION
This function evaluates all physical network interfaces using .NET and displays their cable connection status.
It allows filtering by operational status like Up, Down, Dormant, NotPresent, etc. and supports logging and verbosity.

.PARAMETER Status
Optional filter (array) for operational statuses to include in output. Example: Up, Down, NotPresent

.PARAMETER LogFile
Optional path to a log file to write the output and error messages.

.OUTPUTS
[pscustomobject] containing interface name, description, status, speed, MAC, and link status.

.EXAMPLE
Test-NACableConnection

.EXAMPLE
Test-NACableConnection -Status Down

.EXAMPLE
Test-NACableConnection -Status Up,Down

.EXAMPLE
Test-NACableConnection -LogFile "C:\Logs\cable_check.log"
#>

    [CmdletBinding()]
    param (
        [ValidateSet("Up", "Down", "Testing", "Unknown", "Dormant", "NotPresent", "LowerLayerDown")]
        [string[]]$Status,

        [string]$LogFile
    )

    try {
        Write-Verbose "Retrieving network interface list..."
        if ($LogFile) { Write-NAHelperLog -Message "Retrieving network interface list" -Type Info -Path $LogFile }

        $interfaces = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            Where-Object { $_.NetworkInterfaceType -ne 'Loopback' }

        $results = [System.Collections.Generic.List[object]]::new()

        foreach ($nic in $interfaces) {
            $status = $nic.OperationalStatus.ToString()
            if ($Status -and $status -notin $Status) { continue }

            $obj = [PSCustomObject]@{
                Name        = $nic.Name
                Description = $nic.Description
                Status      = $status
                SpeedMbps   = [math]::Round($nic.Speed / 1MB, 2)
                MAC         = ($nic.GetPhysicalAddress().ToString() -replace '(.{2})(?=.)','$1:')
                LinkStatus  = if ($status -eq 'Up' -and $nic.Speed -gt 0) { 'Connected' } else { 'Disconnected' }
            }

            $obj.PSObject.TypeNames.Insert(0, 'NetzwerkToolkit.NICLinkStatus')
            #Write-Output $obj
            $results.Add($obj)

            if ($LogFile) {
                Write-NAHelperLog -Message "NIC: $($obj.Name) | Status: $($obj.Status) | Link: $($obj.LinkStatus)" -Type Info -Path $LogFile
            }
        }

        return $results
    }
    catch {
        $msg = "Error checking NIC cable connection: $_"
        Write-Error $msg
        if ($LogFile) {
            Write-NAHelperLog -Message $msg -Type Error -Path $LogFile
        }
    }
}