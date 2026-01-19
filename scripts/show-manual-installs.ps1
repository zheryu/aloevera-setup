<#
.SYNOPSIS
    Displays list of apps that require manual installation.

.DESCRIPTION
    Shows applications that cannot be installed via automated provisioning,
    along with download URLs and reasons why automation isn't possible.

.EXAMPLE
    .\show-manual-installs.ps1
#>

$ErrorActionPreference = "Stop"

# Import common utilities
. "$PSScriptRoot/Common.ps1"

Write-InfoBanner "Manual Installation Required"

$uninstallableFile = "$PSScriptRoot/../.config/apps/uninstallable.txt"

if (-not (Test-Path $uninstallableFile)) {
    Write-Host "No manual installations required." -ForegroundColor Green
    exit 0
}

# Parse the file
$apps = Get-Content $uninstallableFile | 
    Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_.Trim() } |
    ForEach-Object {
        $parts = $_ -split '\s*\|\s*', 3
        if ($parts.Count -eq 3) {
            [PSCustomObject]@{
                Name = $parts[0].Trim()
                URL = $parts[1].Trim()
                Reason = $parts[2].Trim()
            }
        }
    }

if ($apps.Count -eq 0) {
    Write-Host "No manual installations required." -ForegroundColor Green
    exit 0
}

Write-Host "The following applications require manual installation:" -ForegroundColor Yellow
Write-Host ""

foreach ($app in $apps) {
    Write-Host "  $($app.Name)" -ForegroundColor Cyan
    Write-Host "    Download: $($app.URL)" -ForegroundColor Gray
    Write-Host "    Reason: $($app.Reason)" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "Please visit the URLs above to download and install these applications." -ForegroundColor Yellow
Write-Host ""

# Ask if user wants to open URLs
$response = Read-Host "Open download pages in browser? (Y/N)"
if ($response -match '^[Yy]') {
    foreach ($app in $apps) {
        Write-Host "Opening $($app.Name)..." -ForegroundColor Gray
        Start-Process $app.URL
        Start-Sleep -Milliseconds 500
    }
}
