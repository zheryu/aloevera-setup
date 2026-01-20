#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap script to install prerequisites for Install-Aloevera module.

.DESCRIPTION
    Run this FIRST on a fresh Windows machine to install:
    - PowerShell 7.5+ (if not already installed)
    - WinGet (if not already installed)
    - Updates both to latest versions
    
    After running this script, restart your shell and then use the Install-Aloevera module.

.EXAMPLE
    .\setup.ps1

.NOTES
    This script can run on PowerShell 5.1+ (built-in Windows PowerShell).
    After installation, use PowerShell 7+ for the Install-Aloevera module.
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Aloevera Prerequisites Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$needsRestart = $false

# Check current PowerShell version
Write-Host "[1/3] Checking PowerShell version..." -ForegroundColor Yellow
$currentVersion = $PSVersionTable.PSVersion
Write-Host "  Current version: $($currentVersion.Major).$($currentVersion.Minor).$($currentVersion.Patch)" -ForegroundColor Gray

if ($currentVersion.Major -lt 7 -or ($currentVersion.Major -eq 7 -and $currentVersion.Minor -lt 5)) {
    Write-Host "  PowerShell 7.5+ required. Installing..." -ForegroundColor Yellow
    
    # Check if WinGet is available to install PowerShell
    try {
        $wingetAvailable = Get-Command winget -ErrorAction Stop
        Write-Host "  Installing PowerShell via WinGet..." -ForegroundColor Gray
        
        winget install --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements --silent
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] PowerShell 7 installed successfully!" -ForegroundColor Green
            $needsRestart = $true
        } else {
            Write-Host "  [WARN] Installation completed with warnings" -ForegroundColor Yellow
            $needsRestart = $true
        }
    } catch {
        Write-Host "  [FAIL] WinGet not available. Please install PowerShell 7 manually:" -ForegroundColor Red
        Write-Host "    https://aka.ms/install-powershell" -ForegroundColor Cyan
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "  [OK] PowerShell 7.5+ already installed" -ForegroundColor Green
}

Write-Host ""

# Check WinGet
Write-Host "[2/3] Checking WinGet..." -ForegroundColor Yellow
try {
    $wingetPath = Get-Command winget -ErrorAction Stop
    $wingetVersion = (winget --version) -replace 'v', ''
    Write-Host "  Current version: $wingetVersion" -ForegroundColor Gray
    
    # Update WinGet to latest
    Write-Host "  Updating WinGet to latest version..." -ForegroundColor Gray
    $output = winget upgrade --id Microsoft.DesktopAppInstaller --accept-source-agreements --silent 2>&1
    
    if ($LASTEXITCODE -eq 0 -or $output -match "No applicable update found") {
        Write-Host "  [OK] WinGet is up to date" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] WinGet update completed with warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [FAIL] WinGet not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install WinGet from the Microsoft Store:" -ForegroundColor Yellow
    Write-Host "    https://aka.ms/getwinget" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Or install manually:" -ForegroundColor Yellow
    Write-Host "    https://github.com/microsoft/winget-cli/releases/latest" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host ""

# Summary
Write-Host "[3/3] Prerequisites Check Complete" -ForegroundColor Yellow
Write-Host ""

if ($needsRestart) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  ACTION REQUIRED" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PowerShell 7 has been installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Close this PowerShell window" -ForegroundColor White
    Write-Host "  2. Open a NEW PowerShell 7 window:" -ForegroundColor White
    Write-Host "     - Search for 'PowerShell 7' in Start Menu" -ForegroundColor Gray
    Write-Host "     - Or run: pwsh" -ForegroundColor Gray
    Write-Host "  3. Navigate back to this directory" -ForegroundColor White
    Write-Host "  4. Run the Aloevera setup:" -ForegroundColor White
    Write-Host "     Import-Module .\Install-Aloevera\Install-Aloevera.psd1" -ForegroundColor Cyan
    Write-Host "     Aloe" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  All Prerequisites Ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use the Install-Aloevera module:" -ForegroundColor Yellow
    Write-Host "  Import-Module .\Install-Aloevera\Install-Aloevera.psd1" -ForegroundColor Cyan
    Write-Host "  Aloe" -ForegroundColor Cyan
    Write-Host ""
}
