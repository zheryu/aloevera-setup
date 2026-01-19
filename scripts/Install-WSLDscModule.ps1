# Install WSL.Dsc module to system-wide PowerShell modules directory
$ModuleSource = Join-Path $PSScriptRoot "..\modules\WSL.Dsc"
$ModuleDest = "C:\Program Files\PowerShell\Modules\WSL.Dsc"

Write-Host "Installing WSL.Dsc module to system-wide location..."
Write-Host "This requires administrator privileges."

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator to install to system modules."
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again."
    exit 1
}

# Create destination directory if it doesn't exist
if (!(Test-Path (Split-Path $ModuleDest))) {
    New-Item -ItemType Directory -Path (Split-Path $ModuleDest) -Force | Out-Null
}

# Copy module files
if (Test-Path $ModuleDest) {
    Remove-Item $ModuleDest -Recurse -Force
}
Copy-Item -Path $ModuleSource -Destination $ModuleDest -Recurse -Force

Write-Host "WSL.Dsc module installed to: $ModuleDest" -ForegroundColor Green
Write-Host "You can now run: winget configure -f .config\wsl-setup.winget --accept-configuration-agreements" -ForegroundColor Cyan
