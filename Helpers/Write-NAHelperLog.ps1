function Write-NAHelperLog {
<#
.SYNOPSIS
Writes structured log entries to a specified log file. Automatically creates the log directory if it doesn't exist.

.PARAMETER Message
The message content to log.

.PARAMETER Type
Type of log entry: Info, Warning, Error.

.PARAMETER Path
The full path to the log file.

.EXAMPLE
Write-NAHelperLog -Message "NIC found" -Type Info -Path "C:\Logs\output.txt"
#>
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("Info", "Warning", "Error")]
        [string]$Type = "Info",

        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "[{0}] [{1}] {2}" -f $timestamp, $Type.ToUpper(), $Message

        # Ensure the directory exists
        $logDir = Split-Path -Path $Path -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $Path -Value $entry
    }
    catch {
        Write-Error "Failed to write log entry: $_"
    }
}