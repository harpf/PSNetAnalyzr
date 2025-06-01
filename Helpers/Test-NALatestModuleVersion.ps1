function Test-NALatestModuleVersion {
    <#
        .SYNOPSIS
        Checks if the local PowerShell module version is up-to-date with the latest GitHub release.

        .PARAMETER Repository
        Der GitHub-Repository in der Form "owner/repo" (z. B. "harpf/PSNetAnalyzr")

        .EXAMPLE
        Test-NALatestModuleVersion -Repository "harpf/PSNetAnalyzr"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Repository
    )

    try {
        # Lokale Modulversion ermitteln
        $scriptDirectory = Split-Path -Path (Split-Path -Path $PSCommandPath -Parent -ErrorAction SilentlyContinue) -Parent
        $manifestFile = Get-ChildItem -Path $scriptDirectory -Filter "*.psd1" -Recurse -ErrorAction Stop | Select-Object -First 1
        $manifest = Import-PowerShellDataFile -Path $manifestFile.FullName
        $localVersion = [version]$manifest.ModuleVersion
        $moduleName = $manifest.RootModule -split '.psm1$' | Select-Object -First 1

        $apiUrl = "https://api.github.com/repos/$Repository/releases/latest"
        $headers = @{ "User-Agent" = "PowerShell" } # GitHub verlangt einen User-Agent
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        $latestVersion = [version]$response.tag_name.TrimStart("v")

        if ($localVersion -lt $latestVersion) {
            Write-Host "[$localVersion] --> [$latestVersion] A newer version of '$moduleName' is available on GitHub!" -ForegroundColor Yellow
        }
        elseif ($localVersion -eq $latestVersion) {
            Write-Information "[$localVersion] The module '$moduleName' is up to date with GitHub release."
        }
        else {
            Write-Warning "Local version [$localVersion] is newer than GitHub release [$latestVersion]."
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
