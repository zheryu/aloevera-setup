function Set-WslConfig {
    <#
    .SYNOPSIS
        Configures WSL settings in /etc/wsl.conf.

    .DESCRIPTION
        Disables automount and configures fstab mounting for WSL distributions.

    .PARAMETER DistributionName
        Name of the WSL distribution to configure. Default: Ubuntu

    .EXAMPLE
        Set-WslConfig
        Set-WslConfig -DistributionName Ubuntu-22.04
    #>

    param(
        [Parameter()]
        [string]$DistributionName = 'Ubuntu'
    )

    Write-Host "Configuring WSL settings for $DistributionName..." -ForegroundColor Cyan

    # Check if distribution exists
    $distros = wsl --list --quiet 2>$null
    if ($distros -notcontains $DistributionName) {
        Write-Error "Distribution '$DistributionName' not found. Available: $($distros -join ', ')"
        return 1
    }

    # Check current config
    $currentConfig = wsl -d $DistributionName -u root cat /etc/wsl.conf 2>$null

    Write-Host "Current wsl.conf content:" -ForegroundColor Yellow
    if ($currentConfig) {
        Write-Host $currentConfig
    } else {
        Write-Host "(file does not exist)"
    }

    # Load the desired config from ~/.aloe/wsl.conf
    $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".aloe\wsl.conf"
    
    if (-not (Test-Path $configPath)) {
        Write-Error "Configuration file not found: $configPath"
        return 1
    }

    $desiredConfig = Get-Content -Path $configPath -Raw

    # Write the config
    Write-Host "`nWriting new configuration..." -ForegroundColor Green
    wsl -d $DistributionName -u root bash -c "echo '$desiredConfig' > /etc/wsl.conf"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Successfully configured wsl.conf" -ForegroundColor Green
        return 0
    } else {
        Write-Error "Failed to write wsl.conf"
        return 1
    }
}