function Install-AloeveraApps {
    <#
    .SYNOPSIS
        Installs applications using WinGet configuration files.

    .DESCRIPTION
        Applies all application configurations from .config/apps directory.
        Supports category-based blocking via blocklist.txt.

    .PARAMETER SkipPrompt
        Skip confirmation prompt and proceed directly with installation.

    .EXAMPLE
        Install-AloeveraApps
        Install-AloeveraApps -SkipPrompt
    #>

    [CmdletBinding()]
    param(
        [switch]$SkipPrompt
    )

    $ErrorActionPreference = "Stop"
    
    Write-InfoBanner "Application Installation"

    # Determine module base directory and config location
    $ModuleBase = Split-Path -Parent $PSScriptRoot
    $AppsDir = Join-Path -Path $ModuleBase -ChildPath ".config\apps"

    if (-not (Test-Path $AppsDir)) {
        Write-Warning "Apps directory not found: $AppsDir"
        Write-Host "Please create .config/apps directory with .winget configuration files."
        return
    }

    # Discover all .winget files in the apps directory
    $AppConfigs = Get-ChildItem -Path $AppsDir -Filter "*.winget" | Select-Object -ExpandProperty FullName

    if ($AppConfigs.Count -eq 0) {
        Write-Warning "No application configuration files found in $AppsDir"
        return
    }

    # Load blocklist
    $BlocklistPath = Join-Path -Path $AppsDir -ChildPath "blocklist.txt"
    $BlockedCategories = @()
    if (Test-Path $BlocklistPath) {
        $BlockedCategories = Get-Content $BlocklistPath | 
            Where-Object { $_ -and $_ -notmatch '^\s*#' -and $_.Trim() } | 
            ForEach-Object { $_.Trim() }
        
        if ($BlockedCategories.Count -gt 0) {
            Write-Host "Blocklist loaded: $($BlockedCategories.Count) category(ies) will be skipped" -ForegroundColor Yellow
            Write-Host ""
        }
    }

    # Filter out blocked categories
    $FilteredConfigs = $AppConfigs | Where-Object {
        $categoryName = (Split-Path $_ -Leaf) -replace '\.winget$', ''
        $categoryName -notin $BlockedCategories
    }

    if ($FilteredConfigs.Count -eq 0) {
        Write-Warning "All categories are blocked. Nothing to install."
        return
    }

    # Show what will be installed
    Write-Host "The following application categories will be installed/updated:" -ForegroundColor Yellow
    Write-Host ""
    
    $totalPackages = 0
    foreach ($configFile in $FilteredConfigs) {
        $categoryName = (Split-Path $configFile -Leaf) -replace '\.winget$', ''
        Write-Host "  $categoryName" -ForegroundColor Cyan
        
        # Parse the YAML to extract package IDs
        $content = Get-Content $configFile
        $packageIds = @()
        $inSettings = $false
        
        foreach ($line in $content) {
            if ($line -match '^\s+settings:\s*$') {
                $inSettings = $true
            }
            if ($inSettings -and $line -match '^\s+id:\s*(.+)$') {
                $packageIds += $matches[1].Trim()
            }
            if ($line -match '^\s+-\s+resource:' -or $line -match '^\s+resources:') {
                $inSettings = $false
            }
        }
        
        $totalPackages += $packageIds.Count
        foreach ($id in $packageIds) {
            Write-Host "    - $id" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Total packages: $totalPackages" -ForegroundColor Cyan
    Write-Host ""

    # Prompt for confirmation unless skipped
    if (-not $SkipPrompt) {
        $response = Read-Host "Proceed with installation? (Y/N)"
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-Host "Installation cancelled by user." -ForegroundColor Yellow
            return
        }
    }

    # Apply each configuration
    Write-Host "`nStarting application installation..." -ForegroundColor Green
    Write-Host ""

    $successCount = 0
    $failCount = 0

    foreach ($configFile in $FilteredConfigs) {
        $categoryName = (Split-Path $configFile -Leaf) -replace '\.winget$', ''
        Write-Host "[Installing: $categoryName]" -ForegroundColor Cyan
        
        try {
            winget configure --file $configFile --accept-configuration-agreements --disable-interactivity
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] $categoryName installed successfully" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "[WARN] $categoryName completed with warnings (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
                $successCount++
            }
        } catch {
            Write-Host "[FAIL] $categoryName installation failed: $_" -ForegroundColor Red
            $failCount++
        }
        
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Installation Summary:" -ForegroundColor Cyan
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "========================================" -ForegroundColor Cyan
}
