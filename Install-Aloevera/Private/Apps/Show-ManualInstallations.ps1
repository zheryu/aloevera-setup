# Manual installations report

function Show-ManualInstallations {
    <#
    .SYNOPSIS
        Displays list of apps that require manual installation.

    .DESCRIPTION
        Shows applications that cannot be installed via automated provisioning,
        along with download URLs and reasons why automation isn't possible.
        
        Reads from ~/.aloe/apps/uninstallable.txt file.

    .EXAMPLE
        Show-ManualInstallations
    #>

    [CmdletBinding()]
    param()

    $UninstallableFile = Join-Path -Path $env:USERPROFILE -ChildPath ".aloe\apps\uninstallable.txt"

    if (-not (Test-Path $UninstallableFile)) {
        # No file means no manual installations needed - silent success
        return
    }

    # Parse the file
    $apps = Get-Content $UninstallableFile | 
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
        # File exists but empty - silent success
        return
    }

    # Display manual installation requirements
    Write-Host ""
    Write-InfoBanner "Manual Installation Required"
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
        Write-Host ""
    }
}
