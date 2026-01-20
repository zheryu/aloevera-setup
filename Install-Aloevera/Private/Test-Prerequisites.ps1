# Prerequisite validation functions

function Test-Prerequisites {
    <#
    .SYNOPSIS
        Validates all prerequisites for Aloevera setup.

    .DESCRIPTION
        Checks:
        - Windows version (Windows 10 build 19041+ or Windows 11)
        - PowerShell version (5.1+)
        - Internet connectivity
        - WinGet availability and version
    #>

    $allChecksPassed = $true

    # Check Windows version
    Write-Host "  Checking Windows version..." -NoNewline
    $osVersion = [System.Environment]::OSVersion.Version
    $buildNumber = [System.Environment]::OSVersion.Version.Build
    
    if ($osVersion.Major -ge 10 -and $buildNumber -ge 19041) {
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "    Windows version: $($osVersion.Major).$($osVersion.Minor) (Build $buildNumber)" -ForegroundColor Gray
    } else {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    Current version: $($osVersion.Major).$($osVersion.Minor) (Build $buildNumber)" -ForegroundColor Gray
        Write-Host "    Requires Windows 10 build 19041+ or Windows 11" -ForegroundColor Red
        $allChecksPassed = $false
    }

    # Check PowerShell version
    Write-Host "  Checking PowerShell version..." -NoNewline
    $psVersion = $PSVersionTable.PSVersion
    
    if ($psVersion.Major -ge 7 -and ($psVersion.Major -gt 7 -or $psVersion.Minor -ge 5)) {
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "    PowerShell version: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Patch)" -ForegroundColor Gray
    } else {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    Current version: $($psVersion.Major).$($psVersion.Minor).$($psVersion.Patch)" -ForegroundColor Gray
        Write-Host "    Requires PowerShell 7.5 or later" -ForegroundColor Red
        $allChecksPassed = $false
    }

    # Check internet connectivity
    Write-Host "  Checking internet connectivity..." -NoNewline
    try {
        $testConnection = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
        if ($testConnection) {
            Write-Host " [OK]" -ForegroundColor Green
        } else {
            Write-Host " [WARN]" -ForegroundColor Yellow
            Write-Host "    Limited or no internet connectivity detected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " [WARN]" -ForegroundColor Yellow
        Write-Host "    Could not verify internet connectivity" -ForegroundColor Yellow
    }

    # Check WinGet availability
    Write-Host "  Checking WinGet..." -NoNewline
    try {
        $wingetPath = Get-Command winget -ErrorAction Stop
        $wingetVersion = (winget --version) -replace 'v', ''
        
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "    WinGet version: $wingetVersion" -ForegroundColor Gray
        
        # Check if version is recent enough (1.4.0+)
        $versionParts = $wingetVersion.Split('.')
        $major = [int]$versionParts[0]
        $minor = [int]$versionParts[1]
        
        if ($major -lt 1 -or ($major -eq 1 -and $minor -lt 4)) {
            Write-Host "    [WARN] WinGet version 1.4.0+ recommended" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    WinGet not found. Install from Microsoft Store: https://aka.ms/getwinget" -ForegroundColor Red
        $allChecksPassed = $false
    }

    # Check Administrator privileges
    Write-Host "  Checking Administrator privileges..." -NoNewline
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "    Must run as Administrator" -ForegroundColor Red
        $allChecksPassed = $false
    }

    if (-not $allChecksPassed) {
        throw "Prerequisites check failed. Please resolve the issues above and try again."
    }

    Write-Host ""
}
