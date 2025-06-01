$PSScriptRoot -replace '.*\\(.*?)\\[^\\]+$', '$1' |
    ForEach-Object { '{0}\{1}.psd1' -f $PSScriptRoot, $_ } |
        Where-Object { Test-Path -Path $_ } |
            Import-Module -Verbose -Force

<# ------------------ PLACE DEBUG COMMANDS AFTER THIS LINE ------------------ #>