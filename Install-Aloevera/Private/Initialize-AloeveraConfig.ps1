function Initialize-AloeveraConfig {
    <#
    .SYNOPSIS
        Initializes the user's Aloevera configuration directory.

    .DESCRIPTION
        Creates ~/.aloe directory and populates it with default configuration files
        from the module's .config template directory. Only copies files if they don't exist.
        
        Configuration location: $env:USERPROFILE\.aloe

    .EXAMPLE
        Initialize-AloeveraConfig
    #>

    [CmdletBinding()]
    param()

    $ConfigDir = Join-Path -Path $env:USERPROFILE -ChildPath ".aloe"
    $ModuleBase = Split-Path -Path $PSScriptRoot -Parent
    $TemplateDir = Join-Path -Path (Split-Path -Path $ModuleBase -Parent) -ChildPath ".config"

    Write-Host "[Config] Checking Aloevera configuration directory..." -NoNewline

    # Create config directory if it doesn't exist
    if (-not (Test-Path $ConfigDir)) {
        Write-Host " creating" -ForegroundColor Yellow
        New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
        Write-Host "  Created: $ConfigDir" -ForegroundColor Gray
    } else {
        Write-Host " [OK]" -ForegroundColor Green
    }

    # Check if template directory exists
    if (-not (Test-Path $TemplateDir)) {
        Write-Warning "Template directory not found: $TemplateDir"
        Write-Warning "Configuration files must be created manually in: $ConfigDir"
        return
    }

    # Copy template files if they don't exist
    $copied = 0
    $skipped = 0

    # Copy apps directory
    $AppsSourceDir = Join-Path -Path $TemplateDir -ChildPath "apps"
    $AppsDestDir = Join-Path -Path $ConfigDir -ChildPath "apps"

    if (Test-Path $AppsSourceDir) {
        if (-not (Test-Path $AppsDestDir)) {
            New-Item -Path $AppsDestDir -ItemType Directory -Force | Out-Null
        }

        Get-ChildItem -Path $AppsSourceDir -File | ForEach-Object {
            $destPath = Join-Path -Path $AppsDestDir -ChildPath $_.Name
            if (-not (Test-Path $destPath)) {
                Copy-Item -Path $_.FullName -Destination $destPath -Force
                Write-Host "  [+] $($_.Name)" -ForegroundColor Cyan
                $copied++
            } else {
                $skipped++
            }
        }
    }

    # Copy wsl-setup.winget
    $WslSource = Join-Path -Path $TemplateDir -ChildPath "wsl-setup.winget"
    $WslDest = Join-Path -Path $ConfigDir -ChildPath "wsl-setup.winget"

    if (Test-Path $WslSource) {
        if (-not (Test-Path $WslDest)) {
            Copy-Item -Path $WslSource -Destination $WslDest -Force
            Write-Host "  [+] wsl-setup.winget" -ForegroundColor Cyan
            $copied++
        } else {
            $skipped++
        }
    }

    # Create README if it doesn't exist
    $ReadmePath = Join-Path -Path $ConfigDir -ChildPath "README.md"
    if (-not (Test-Path $ReadmePath)) {
        $readmeContent = @"
# Aloevera Configuration Directory

This directory contains your personal Aloevera setup configuration.

## Structure

- **apps/**: WinGet configuration files for applications
  - *.winget: Application category files (development, communication, media, etc.)
  - blocklist.txt: Categories to skip during installation
  - uninstallable.txt: Apps that require manual installation

- **wsl-setup.winget**: WSL and Ubuntu installation configuration

## Customization

Edit these files to customize your setup:
1. Add/remove apps from *.winget files
2. Add categories to blocklist.txt to skip them
3. Modify wsl-setup.winget for custom WSL settings

## Reset

To reset to defaults, delete this directory and run:

powershell
Install-Aloevera


The configuration will be regenerated from module templates.
"@
        Set-Content -Path $ReadmePath -Value $readmeContent -Encoding UTF8
        Write-Host "  [+] README.md" -ForegroundColor Cyan
        $copied++
    } else {
        $skipped++
    }

    if ($copied -gt 0) {
        Write-Host "`n  Initialized $copied file(s) in: $ConfigDir" -ForegroundColor Green
    }

    if ($skipped -gt 0) {
        Write-Host "  Existing files preserved: $skipped" -ForegroundColor Gray
    }

    return $ConfigDir
}
