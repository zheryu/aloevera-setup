#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs and configures WSL (Windows Subsystem for Linux) prerequisites.

.DESCRIPTION
    Checks if WSL is installed and enabled. If not, enables the required Windows features
    and installs WSL. May require a system reboot.

.NOTES
    This script handles the WSL feature installation and will inform the user if a reboot is needed.
#>

$ErrorActionPreference = "Stop"

# Import common utilities
. "$PSScriptRoot/Common.ps1"

Write-Host "Checking WSL installation status..." -ForegroundColor Gray

try {
    # Check if WSL is already installed
    $wslStatus = wsl --status 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] WSL is already installed and configured" -ForegroundColor Green
        
        # Display WSL version info
        $wslVersion = wsl --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WSL Version Information:" -ForegroundColor Gray
            Write-Host $wslVersion -ForegroundColor Gray
        }
        
        return
    }
} catch {
    # WSL not installed, continue with installation
}

Write-Host "WSL not detected. Installing WSL..." -ForegroundColor Yellow

# Check if WSL features are enabled
$vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue

$rebootRequired = $false

# Enable Virtual Machine Platform
if ($vmpFeature.State -ne "Enabled") {
    Write-Host "Enabling Virtual Machine Platform feature..." -ForegroundColor Gray
    $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    if ($result.RestartNeeded) {
        $rebootRequired = $true
    }
}

# Enable WSL feature
if ($wslFeature.State -ne "Enabled") {
    Write-Host "Enabling Windows Subsystem for Linux feature..." -ForegroundColor Gray
    $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    if ($result.RestartNeeded) {
        $rebootRequired = $true
    }
}

# Install WSL using the modern method
try {
    Write-Host "Installing WSL kernel and components..." -ForegroundColor Gray
    wsl --install --no-distribution
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] WSL installation initiated successfully" -ForegroundColor Green
    }
} catch {
    Write-Warning "WSL install command failed, but features are enabled. This may be normal."
}

# Check if reboot is required
if ($rebootRequired) {
    Write-WarningBanner "REBOOT REQUIRED"
    Write-Host "Windows features have been enabled, but a restart is required." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Restart your computer now"
    Write-Host "  2. After restart, run bootstrap.ps1 again to continue setup"
    Write-Host ""
    
    $response = Read-Host "Would you like to restart now? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Host "Please restart manually and re-run bootstrap.ps1" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "[OK] WSL prerequisites configured (no reboot needed)" -ForegroundColor Green
}
