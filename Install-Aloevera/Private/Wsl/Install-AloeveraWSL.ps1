function Install-AloeveraWSL {
    <#
    .SYNOPSIS
        Installs and configures WSL with Ubuntu distribution.

    .DESCRIPTION
        Complete WSL setup including:
        - WSL feature installation and prerequisites
        - Ubuntu distribution installation via WinGet DSC
        - WSL configuration (wsl.conf)
        - fstab configuration for drive mounting
        
        May require system reboot if WSL features need to be enabled.

    .EXAMPLE
        Install-AloeveraWSL
    #>

    [CmdletBinding()]
    param()

    $ErrorActionPreference = "Stop"
    
    Write-InfoBanner "WSL Setup"
    
    # Determine paths
    $ConfigDir = Join-Path -Path $env:USERPROFILE -ChildPath ".aloe"

    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  1. Install/verify WSL prerequisites"
    Write-Host "  2. Install Ubuntu via WinGet DSC"
    Write-Host "  3. Create Ubuntu user account"
    Write-Host "  4. Configure WSL automount settings"
    Write-Host "  5. Configure fstab for built-in drives"
    Write-Host ""

    # Step 1: Install WSL prerequisites
    Write-Host "[1/5] Checking WSL prerequisites..." -ForegroundColor Green
    
    try {
        $wslStatus = wsl --status 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] WSL is already installed and configured" -ForegroundColor Green
            
            # Display WSL version info
            $wslVersion = wsl --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $wslVersion) {
                Write-Host "WSL Version Information:" -ForegroundColor Gray
                $wslVersion | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            }
        }
    } catch {
        Write-Host "WSL not detected. Installing WSL..." -ForegroundColor Yellow
        
        # Check if WSL features are enabled
        $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue

        $rebootRequired = $false

        # Enable Virtual Machine Platform
        if ($vmpFeature.State -ne "Enabled") {
            Write-Host "  Enabling Virtual Machine Platform feature..." -ForegroundColor Gray
            $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
            if ($result.RestartNeeded) {
                $rebootRequired = $true
            }
        }

        # Enable WSL feature
        if ($wslFeature.State -ne "Enabled") {
            Write-Host "  Enabling Windows Subsystem for Linux feature..." -ForegroundColor Gray
            $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            if ($result.RestartNeeded) {
                $rebootRequired = $true
            }
        }

        # Install WSL using the modern method
        try {
            Write-Host "  Installing WSL kernel and components..." -ForegroundColor Gray
            wsl --install --no-distribution 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] WSL installation initiated successfully" -ForegroundColor Green
            }
        } catch {
            Write-Warning "WSL install command failed, but features are enabled. This may be normal."
        }

        # Check if reboot is required
        if ($rebootRequired) {
            Write-WarningBanner "REBOOT REQUIRED"
            Write-Host "Windows features have been enabled but require a system reboot." -ForegroundColor Yellow
            Write-Host "Please reboot your computer and run this command again." -ForegroundColor Yellow
            Write-Host ""
            return
        }
    }

    # Step 2: Install Ubuntu distribution
    Write-Host "`n[2/5] Installing Ubuntu distribution..." -ForegroundColor Green
    $ConfigPath = Join-Path -Path $ConfigDir -ChildPath "wsl-setup.winget"
    
    if (-not (Test-Path $ConfigPath)) {
        throw "WSL configuration file not found: $ConfigPath`nPlease ensure ~/.aloe/wsl-setup.winget exists. Run Install-Aloevera to initialize configuration."
    }
    
    winget configure --file $ConfigPath --accept-configuration-agreements --disable-interactivity
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Ubuntu installed successfully" -ForegroundColor Green
    } else {
        Write-Warning "Ubuntu installation completed with warnings (Exit code: $LASTEXITCODE)"
    }

    # Give WSL a moment to initialize
    Start-Sleep -Seconds 2

    # Step 3: Create Ubuntu user account
    Write-Host "`n[3/5] Creating Ubuntu user account..." -ForegroundColor Green
    try {
        Initialize-UbuntuUser -DistributionName "Ubuntu"
    } catch {
        Write-Warning "Ubuntu user setup failed: $_"
        Write-Host "You may need to set up the user manually on first launch." -ForegroundColor Yellow
    }

    # Step 4: Configure wsl.conf
    Write-Host "`n[4/5] Configuring WSL settings..." -ForegroundColor Green
    try {
        $configResult = Set-WslConfig -DistributionName "Ubuntu"
        if ($configResult -eq 0) {
            Write-Host "[OK] WSL settings configured" -ForegroundColor Green
        } else {
            Write-Warning "WSL config completed with warnings"
        }
    } catch {
        Write-Warning "WSL config failed: $_"
    }

    # Step 5: Configure fstab
    Write-Host "`n[5/5] Configuring fstab..." -ForegroundColor Green
    try {
        $fstabResult = Set-WslFstab -DistributionName "Ubuntu"
        if ($fstabResult -eq 0) {
            Write-Host "[OK] fstab configured" -ForegroundColor Green
        } else {
            Write-Warning "fstab configuration completed with warnings"
        }
    } catch {
        Write-Warning "fstab configuration failed: $_"
    }

    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  WSL Setup Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Run 'wsl --shutdown' and restart WSL for all changes to take effect" -ForegroundColor Yellow
    Write-Host ""
}
