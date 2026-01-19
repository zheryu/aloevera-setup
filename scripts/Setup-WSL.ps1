# Master setup script for WSL configuration
# Installs Ubuntu and configures WSL settings

Write-Host "`n=== WSL Setup ===" -ForegroundColor Cyan
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Install Ubuntu via WinGet DSC"
Write-Host "  2. Configure WSL automount settings"
Write-Host "  3. Configure fstab for built-in drives only"
Write-Host ""

$scriptDir = $PSScriptRoot

# Step 1: Run WinGet configuration to install Ubuntu
Write-Host "`n[1/3] Installing Ubuntu distribution..." -ForegroundColor Green
$configPath = Join-Path $scriptDir "..\.config\wsl-setup.winget"

winget configure -f $configPath --accept-configuration-agreements

if ($LASTEXITCODE -ne 0) {
    Write-Error "WinGet configuration failed"
    exit 1
}

# Give WSL a moment to initialize
Start-Sleep -Seconds 2

# Step 2: Configure wsl.conf
Write-Host "`n[2/3] Configuring WSL settings..." -ForegroundColor Green
& (Join-Path $scriptDir "wsl\wslconfig.ps1")

if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL config failed"
    exit 1
}

# Step 3: Configure fstab
Write-Host "`n[3/3] Configuring fstab..." -ForegroundColor Green
& (Join-Path $scriptDir "wsl\wslfstab.ps1")

if ($LASTEXITCODE -ne 0) {
    Write-Error "fstab configuration failed"
    exit 1
}

# Final reminder
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "[OK] Ubuntu installed" -ForegroundColor Green
Write-Host "[OK] WSL settings configured" -ForegroundColor Green
Write-Host "[OK] fstab configured" -ForegroundColor Green
Write-Host "`nIMPORTANT: Run 'wsl --shutdown' and restart WSL for all changes to take effect" -ForegroundColor Yellow
