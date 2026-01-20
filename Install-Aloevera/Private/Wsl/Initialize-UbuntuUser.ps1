# Ubuntu user account initialization

function Initialize-UbuntuUser {
    <#
    .SYNOPSIS
        Creates and configures a user account in Ubuntu distribution.

    .DESCRIPTION
        Non-interactive Ubuntu user setup that:
        - Prompts for username (default: aloevera)
        - Creates user account with home directory and sudo access
        - Prompts for password with confirmation
        - Configures passwordless sudo
        - Sets as default user for the distribution

    .PARAMETER DistributionName
        Name of the WSL distribution to configure (default: Ubuntu)

    .EXAMPLE
        Initialize-UbuntuUser
        Initialize-UbuntuUser -DistributionName "Ubuntu-22.04"
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DistributionName = "Ubuntu"
    )

    $ErrorActionPreference = "Stop"

    Write-Host "Setting up Ubuntu user account..." -ForegroundColor Gray
    Write-Host ""

    # Prompt for username with default
    $defaultUser = "aloevera"
    $userInput = Read-Host "Enter Ubuntu username (default: $defaultUser)"
    $user = if ([string]::IsNullOrWhiteSpace($userInput)) { $defaultUser } else { $userInput.ToLower() }

    Write-Host "  Creating user: $user" -ForegroundColor Gray

    # Check if user already exists
    $userCheck = wsl -d $DistributionName -u root -- id -u $user 2>$null
    $userAlreadyExists = ($LASTEXITCODE -eq 0)
    $shouldSetPassword = $true

    if ($userAlreadyExists) {
        Write-Host ""
        Write-Host "  User '$user' already exists in Ubuntu." -ForegroundColor Yellow
        $changePassword = Read-Host "  Do you want to change the password? (y/N)"
        $shouldSetPassword = ($changePassword -match '^[Yy]')
    } else {
        # Create user with home directory, add to sudo group
        try {
            wsl -d $DistributionName -u root -- useradd -m -G sudo -s /bin/bash $user
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create user in Ubuntu (exit code: $LASTEXITCODE)"
            }
        } catch {
            throw "Failed to configure Ubuntu user: $_"
        }
    }

    # Prompt for password if needed
    if ($shouldSetPassword) {
        Write-Host ""
        Write-Host "  Please create a password for the Ubuntu user '$user':" -ForegroundColor Yellow
        $securePassword = Read-Host "  Enter password" -AsSecureString
        $confirmPassword = Read-Host "  Confirm password" -AsSecureString

        # Convert to plain text for comparison
        $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
        $pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword))

        if ($pwd1 -ne $pwd2) {
            throw "Passwords do not match. Please run the script again."
        }

        Write-Host ""
        Write-Host "  Setting password..." -ForegroundColor Gray
        $passwordInput = "$pwd1`n$pwd1"
        $passwordInput | wsl -d $DistributionName -u root -- passwd $user 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set user password"
        }

        # Clear password from memory
        $pwd1 = $null
        $pwd2 = $null
    } else {
        Write-Host "  Skipping password change." -ForegroundColor Gray
    }

    # Add passwordless sudo for convenience
    Write-Host "  Configuring sudo access..." -ForegroundColor Gray
    wsl -d $DistributionName -u root -- bash -c "echo '$user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$user"
    wsl -d $DistributionName -u root -- chmod 0440 /etc/sudoers.d/$user

    # Set as default user for the distribution
    Write-Host "  Setting default user..." -ForegroundColor Gray
    try {
        # Try using ubuntu config command (available on newer versions)
        ubuntu config --default-user $user 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            # Fallback: modify /etc/wsl.conf
            $wslConfContent = "[user]`ndefault=$user"
            wsl -d $DistributionName -u root -- bash -c "echo '$wslConfContent' >> /etc/wsl.conf"
            
            # Restart WSL to apply changes
            wsl --shutdown
            Start-Sleep -Seconds 3
        }
    } catch {
        Write-Warning "Could not set default user automatically. You may need to set it manually."
    }

    if ($userAlreadyExists) {
        Write-Host "[OK] User account verified and configured" -ForegroundColor Green
    } else {
        Write-Host "[OK] User account created successfully" -ForegroundColor Green
    }
    
    Write-Host "  Username: $user" -ForegroundColor Gray
    Write-Host ""
}
