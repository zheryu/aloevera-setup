#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Main orchestrator for Windows machine provisioning using WinGet DSC.

.DESCRIPTION
    Multi-stage bootstrap that handles:
    - WSL prerequisites and feature installation
    - Non-interactive Ubuntu setup
    - WinGet configuration application
    - Complete logging and error handling

.NOTES
    Run this script as Administrator on a fresh Windows 11 machine.
#>

$ErrorActionPreference = "Stop"

# Create logs directory if it doesn't exist
$logDir = "C:/projects/aloevera-setup/logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$logPath = "$logDir/bootstrap-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $logPath -Append

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  WinGet DSC Machine Provisioning" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Validate prerequisites
    Write-Host "[Prerequisite Check]" -ForegroundColor Yellow
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        throw "This script requires Windows 10 or later"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "This script requires PowerShell 5.0 or later"
    }
    
    # Check internet connectivity
    try {
        $null = Test-Connection -ComputerName "www.microsoft.com" -Count 1 -ErrorAction Stop
        Write-Host "[OK] Internet connectivity verified" -ForegroundColor Green
    } catch {
        throw "No internet connection detected. Please connect to the internet and try again."
    }
    
    Write-Host ""

    # Stage 1: WSL Prerequisites
    Write-Host "--- Stage 1: WSL Prerequisites ---" -ForegroundColor Cyan
    & "$PSScriptRoot/install-wsl.ps1"
    Write-Host ""

    # Stage 2: WinGet Core Apps
    Write-Host "--- Stage 2: Update WinGet ---" -ForegroundColor Cyan
    Write-Host "Updating WinGet package manager..." -ForegroundColor Gray
    
    # Update only the WinGet installer itself to avoid massive side effects
    try {
        winget upgrade --id Microsoft.DesktopAppInstaller --accept-source-agreements --silent
        Write-Host "[OK] WinGet updated successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to update WinGet, continuing with existing version..."
    }
    Write-Host ""

    # Stage 3: Ubuntu Non-Interactive Setup
    Write-Host "--- Stage 3: Ubuntu Non-Interactive Setup ---" -ForegroundColor Cyan
    & "$PSScriptRoot/setup-ubuntu.ps1"
    Write-Host ""

    # Stage 4: WSL Setup
    Write-Host "--- Stage 4: WSL Setup ---" -ForegroundColor Cyan
    Write-Host "Configuring WSL environment..." -ForegroundColor Gray
    
    $wslConfigFile = "C:/projects/aloevera-setup/.config/wsl-setup.winget"
    if (-not (Test-Path $wslConfigFile)) {
        throw "Configuration file not found: $wslConfigFile"
    }
    
    winget configure -f $wslConfigFile --accept-configuration-agreements
    Write-Host ""

    # Stage 5: Application Installation
    Write-Host "--- Stage 5: Application Installation ---" -ForegroundColor Cyan
    
    $appConfigs = @(
        "C:/projects/aloevera-setup/.config/apps/development.winget",
        "C:/projects/aloevera-setup/.config/apps/communication.winget",
        "C:/projects/aloevera-setup/.config/apps/media.winget",
        "C:/projects/aloevera-setup/.config/apps/productivity.winget"
    )
    
    foreach ($configFile in $appConfigs) {
        if (-not (Test-Path $configFile)) {
            Write-Warning "Configuration file not found: $configFile (skipping)"
            continue
        }
        
        $categoryName = (Split-Path $configFile -Leaf) -replace '\.winget$', ''
        Write-Host "Installing $categoryName apps..." -ForegroundColor Gray
        winget configure -f $configFile --accept-configuration-agreements
    }
    Write-Host ""

    # Success summary
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Provisioning Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Log file saved to: $logPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the log file for any warnings or errors"
    Write-Host "  2. Restart your computer if prompted"
    Write-Host "  3. Verify WSL is working: wsl --list --verbose"
    Write-Host "  4. Update Git config if needed: git config --global user.name/email"
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Provisioning Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the log file for details: $logPath" -ForegroundColor Gray
    Write-Host ""
    
    exit 1
} finally {
    Stop-Transcript
}
