#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Non-interactive Ubuntu installation and configuration for WSL.

.DESCRIPTION
    Installs Ubuntu via WinGet, creates a user account non-interactively,
    and configures sudo access. This bypasses the normal Ubuntu OOBE prompts.
.NOTES
#>

$ErrorActionPreference = "Stop"

# Distribution configuration
$distro = "Ubuntu"

Write-Host "Setting up Ubuntu for WSL..." -ForegroundColor Gray
Write-Host "Target distribution: $distro" -ForegroundColor Gray
Write-Host ""

# Prompt for username with default
$defaultUser = "aloevera"
$userInput = Read-Host "Enter Ubuntu username (default: $defaultUser)"
$user = if ([string]::IsNullOrWhiteSpace($userInput)) { $defaultUser } else { $userInput.ToLower() }

Write-Host "User to create: $user" -ForegroundColor Gray
Write-Host ""

# Check if Ubuntu is already installed and configured
$existingDistros = wsl --list --quiet 2>$null

if ($existingDistros -match $distro) {
    Write-Host "Ubuntu distribution already exists" -ForegroundColor Gray
    
    # Check if user already exists
    $userCheck = wsl -d $distro -- id -u $user 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] User '$user' already exists in Ubuntu" -ForegroundColor Green
        return
    }
} else {
    # Install Ubuntu if not present
    Write-Host "Installing Ubuntu distribution..." -ForegroundColor Gray
    
    # Install via WinGet but don't launch (prevents OOBE prompt)
    winget install --id Canonical.Ubuntu --exact --accept-package-agreements --accept-source-agreements --silent
    
    # Exit codes: 0 = success, -1978335189 = already installed (no upgrade available)
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        throw "Failed to install Ubuntu via WinGet (exit code: $LASTEXITCODE)"
    }
    
    Write-Host "[OK] Ubuntu installed" -ForegroundColor Green
    Write-Host ""
    
    # Wait for distribution to be registered
    Write-Host "Waiting for Ubuntu to be registered with WSL..." -ForegroundColor Gray
    $maxRetries = 10
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 2
        $distros = wsl --list --quiet 2>$null
        if ($distros -contains $distro) {
            Write-Host "[OK] Ubuntu registered with WSL" -ForegroundColor Green
            break
        }
        $retryCount++
    }
    
    if ($retryCount -eq $maxRetries) {
        throw "Ubuntu installation timeout - distribution not registered with WSL"
    }
    
    Write-Host ""
}

Write-Host "Creating user account in Ubuntu..." -ForegroundColor Gray
Write-Host ""
Write-Host "Setting up user account..." -ForegroundColor Gray

try {
    # Create user with home directory, add to sudo group
    wsl -d $distro -u root -- useradd -m -G sudo -s /bin/bash $user
    
    # Exit code 9 = user already exists
    $userAlreadyExists = $false
    $shouldSetPassword = $true
    
    if ($LASTEXITCODE -eq 9) {
        $userAlreadyExists = $true
        Write-Host ""
        Write-Host "User '$user' already exists in Ubuntu." -ForegroundColor Yellow
        $changePassword = Read-Host "Do you want to change the password? (y/N)"
        $shouldSetPassword = ($changePassword -match '^[Yy]')
    } elseif ($LASTEXITCODE -ne 0) {
        throw "Failed to create user in Ubuntu (exit code: $LASTEXITCODE)"
    }
    
    # Prompt for password if needed
    if ($shouldSetPassword) {
        Write-Host ""
        Write-Host "Please create a password for the Ubuntu user '$user':" -ForegroundColor Yellow
        $securePassword = Read-Host "Enter password" -AsSecureString
        $confirmPassword = Read-Host "Confirm password" -AsSecureString

        # Convert to plain text for comparison
        $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        $pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword))

        if ($pwd1 -ne $pwd2) {
            throw "Passwords do not match. Please run the script again."
        }

        Write-Host ""
        Write-Host "Updating password..." -ForegroundColor Gray
        $passwordInput = "$pwd1`n$pwd1"
        $passwordInput | wsl -d $distro -u root -- passwd $user
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set user password"
        }
    } else {
        Write-Host "Skipping password change." -ForegroundColor Gray
    }
    
    # Add passwordless sudo for convenience (optional - remove if you want password prompts)
    wsl -d $distro -u root -- bash -c "echo '$user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$user"
    wsl -d $distro -u root -- chmod 0440 /etc/sudoers.d/$user
    
    if ($userAlreadyExists) {
        Write-Host "[OK] User account verified" -ForegroundColor Green
    } else {
        Write-Host "[OK] User account created successfully" -ForegroundColor Green
    }
    
} catch {
    throw "Failed to configure Ubuntu user: $_"
} finally {
    # Clear password from memory
    $pwd1 = $null
    $pwd2 = $null
}

# Set as default user for the distribution
Write-Host "Setting default user for Ubuntu..." -ForegroundColor Gray

try {
    # Try using ubuntu config command (available on newer versions)
    ubuntu config --default-user $user 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Default user set via ubuntu config" -ForegroundColor Green
    } else {
        # Fallback: modify /etc/wsl.conf
        Write-Host "Using wsl.conf method to set default user..." -ForegroundColor Gray
        $wslConfContent = "[user]`ndefault=$user"
        wsl -d $distro -u root -- bash -c "echo '$wslConfContent' >> /etc/wsl.conf"
        
        # Restart WSL to apply changes
        wsl --shutdown
        Start-Sleep -Seconds 3
        
        Write-Host "[OK] Default user set via wsl.conf" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not set default user automatically. You may need to set it manually."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Ubuntu Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Distribution: $distro" -ForegroundColor Gray
Write-Host "Username: $user" -ForegroundColor Gray
Write-Host ""
Write-Host "Test your installation: wsl -d $distro" -ForegroundColor Gray
Write-Host ""
