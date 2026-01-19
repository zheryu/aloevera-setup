#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs or updates applications from WinGet configuration files.

.DESCRIPTION
    Applies all application configurations from .config/apps directory.
    Can be run standalone or called from bootstrap.ps1.

.PARAMETER SkipPrompt
    Skip confirmation prompt and proceed directly with installation.

.EXAMPLE
    .\install-apps.ps1
    .\install-apps.ps1 -SkipPrompt
#>

param(
    [switch]$SkipPrompt
)

$ErrorActionPreference = "Stop"

# Import common utilities
. "$PSScriptRoot/Common.ps1"

Write-InfoBanner "Application Installation"

# Discover all .winget files in the apps directory
$appsDir = "$PSScriptRoot/../.config/apps"
$appConfigs = Get-ChildItem -Path $appsDir -Filter "*.winget" | Select-Object -ExpandProperty FullName

if ($appConfigs.Count -eq 0) {
    Write-Warning "No application configuration files found in $appsDir"
    exit 0
}

# Load blocklist
$blocklistPath = "$appsDir/blocklist.txt"
$blockedCategories = @()
if (Test-Path $blocklistPath) {
    $blockedCategories = Get-Content $blocklistPath | 
        Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_.Trim() } | 
        ForEach-Object { $_.Trim() }
    
    if ($blockedCategories.Count -gt 0) {
        Write-Host "Blocklist loaded: $($blockedCategories.Count) category(ies) will be skipped" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Filter out blocked categories
$filteredConfigs = $appConfigs | Where-Object {
    $categoryName = (Split-Path $_ -Leaf) -replace '\.winget$', ''
    $categoryName -notin $blockedCategories
}

if ($filteredConfigs.Count -eq 0) {
    Write-Warning "All categories are blocked. Nothing to install."
    exit 0
}

# Show what will be installed
Write-Host "The following application categories will be installed/updated:" -ForegroundColor Yellow
Write-Host ""
foreach ($configFile in $filteredConfigs) {
    $categoryName = (Split-Path $configFile -Leaf) -replace '\.winget$', ''
    Write-Host "  $categoryName" -ForegroundColor Cyan
    
    # Parse the YAML to extract package IDs from settings sections
    $content = Get-Content $configFile
    $packageIds = @()
    $inSettings = $false
    
    foreach ($line in $content) {
        # Track when we're in a settings section
        if ($line -match '^\s+settings:\s*$') {
            $inSettings = $true
        }
        # Look for id: lines within settings sections
        elseif ($inSettings -and $line -match '^\s+id:\s+(.+?)\s*$') {
            $id = $matches[1].Trim()
            # Check if it's a package ID (contains a dot)
            if ($id -match '\.') {
                $packageIds += $id
                $inSettings = $false
            }
        }
        # Reset if we hit another top-level key
        elseif ($line -match '^\s+(resource|directives):\s*') {
            $inSettings = $false
        }
    }
    
    if ($packageIds.Count -gt 0) {
        foreach ($id in $packageIds) {
            # Extract app name from package ID (e.g., "Spotify.Spotify" -> "Spotify")
            $appName = ($id -split '\.')[-1]
            Write-Host "    - $appName ($id)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    (No apps found)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
}

if ($blockedCategories.Count -gt 0) {
    Write-Host ""
    Write-Host "Blocked categories (will be skipped):" -ForegroundColor DarkGray
    foreach ($blocked in $blockedCategories) {
        Write-Host "  - $blocked" -ForegroundColor DarkGray
    }
}
Write-Host ""

# Prompt for confirmation unless SkipPrompt is set
if (-not $SkipPrompt) {
    $response = Read-Host "Continue with installation? (Y/N)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Install each category
$installedCount = 0
$skippedCount = 0

foreach ($configFile in $filteredConfigs) {
    $categoryName = (Split-Path $configFile -Leaf) -replace '\.winget$', ''
    Write-Host "Installing $categoryName apps..." -ForegroundColor Cyan
    
    try {
        winget configure -f $configFile --accept-configuration-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $categoryName apps installed" -ForegroundColor Green
            $installedCount++
        } else {
            Write-Warning "Some issues occurred installing $categoryName apps (exit code: $LASTEXITCODE)"
        }
    } catch {
        Write-Warning "Failed to install $categoryName apps: $_"
    }
    
    Write-Host ""
}

# Summary
Write-SuccessBanner "Application Installation Complete!"

Write-Host "Summary:" -ForegroundColor Gray
Write-Host "  Categories installed: $installedCount" -ForegroundColor Green
if ($blockedCategories.Count -gt 0) {
    Write-Host "  Categories blocked: $($blockedCategories.Count)" -ForegroundColor DarkGray
}
Write-Host ""
