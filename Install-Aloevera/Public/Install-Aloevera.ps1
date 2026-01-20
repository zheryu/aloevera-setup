#Requires -Version 7.5
#Requires -RunAsAdministrator

function Install-Aloevera {
    <#
    .SYNOPSIS
        Automated Windows 11 workstation setup using WinGet DSC.

    .DESCRIPTION
        Orchestrates Windows machine provisioning including:
        - Prerequisite validation (OS version, PowerShell, WinGet, internet)
        - WSL installation and Ubuntu configuration
        - Application installation via WinGet DSC
        - Complete logging and error handling

    .PARAMETER Component
        Specify which components to install. Valid values: Apps, WSL
        If not specified, runs full setup (both Apps and WSL).

    .PARAMETER SkipPrerequisites
        Skip prerequisite checks. Use with caution.

    .EXAMPLE
        Install-Aloevera
        Runs full setup with all components

    .EXAMPLE
        Install-Aloevera -Component Apps
        Only installs applications, skips WSL setup

    .EXAMPLE
        Install-Aloevera -Component WSL,Apps
        Installs both WSL and applications (explicit)

    .EXAMPLE
        Aloe
        Uses alias to run full setup

    .NOTES
        Requires Administrator privileges.
        Creates logs in the module's logs directory.
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Apps', 'WSL')]
        [string[]]$Component,

        [Parameter()]
        [switch]$SkipPrerequisites
    )

    $ErrorActionPreference = "Stop"

    # Determine module base directory
    $ModuleBase = Split-Path -Parent $PSScriptRoot
    $LogDir = Join-Path -Path $ModuleBase -ChildPath 'logs'
    
    # Create logs directory if it doesn't exist
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $LogPath = Join-Path -Path $LogDir -ChildPath "aloevera-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Start-Transcript -Path $LogPath -Append

    try {
        Write-InfoBanner "Aloevera Setup - Windows Workstation Provisioning"

        # Initialize configuration directory
        Write-Host ""
        Initialize-AloeveraConfig | Out-Null

        # Validate prerequisites unless skipped
        if (-not $SkipPrerequisites) {
            Write-Host "`n[Prerequisite Check]" -ForegroundColor Yellow
            Test-Prerequisites
        }

        # Determine what to install
        $installApps = $false
        $installWSL = $false

        if (-not $Component -or $Component.Count -eq 0) {
            # No component specified - install everything
            $installApps = $true
            $installWSL = $true
        } else {
            $installApps = $Component -contains 'Apps'
            $installWSL = $Component -contains 'WSL'
        }

        # Execute components
        if ($installWSL) {
            Write-Host "`n[WSL Setup]" -ForegroundColor Cyan
            Install-AloeveraWSL
        }

        if ($installApps) {
            Write-Host "`n[Application Installation]" -ForegroundColor Cyan
            Install-AloeveraApps

            # Show manual installation requirements (if any)
            Show-ManualInstallations
        }

        # Success summary with next steps
        Write-Host ""
        Write-SuccessBanner "Aloevera Setup Complete!"
        Write-Host "Log file saved to: $LogPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Review the log file for any warnings or errors" -ForegroundColor White
        
        if ($installWSL) {
            Write-Host "  2. Restart your computer if prompted" -ForegroundColor White
            Write-Host "  3. Verify WSL is working: " -NoNewline -ForegroundColor White
            Write-Host "wsl --list --verbose" -ForegroundColor Cyan
            Write-Host "  4. Update Git config if needed: " -NoNewline -ForegroundColor White
            Write-Host "git config --global user.name/email" -ForegroundColor Cyan
        } else {
            Write-Host "  2. Restart applications to ensure updates are applied" -ForegroundColor White
        }
        
        Write-Host ""

    } catch {
        Write-ErrorBanner "Setup Failed!"
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Check log for details: $LogPath" -ForegroundColor Gray
        Write-Host ""
        throw
    } finally {
        Stop-Transcript
    }
}
