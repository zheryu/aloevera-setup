# Configure WSL settings in /etc/wsl.conf
# Disables automount and configures fstab mounting

param(
    [Parameter()]
    [string]$DistributionName = 'Ubuntu'
)

Write-Host "Configuring WSL settings for $DistributionName..." -ForegroundColor Cyan

# Check if distribution exists
$distros = wsl --list --quiet 2>$null
if ($distros -notcontains $DistributionName) {
    Write-Error "Distribution '$DistributionName' not found. Available: $($distros -join ', ')"
    exit 1
}

# Check current config
$currentConfig = wsl -d $DistributionName -u root cat /etc/wsl.conf 2>$null

Write-Host "Current wsl.conf content:" -ForegroundColor Yellow
if ($currentConfig) {
    Write-Host $currentConfig
} else {
    Write-Host "(file does not exist)"
}

# Create the desired config
$desiredConfig = @"
[automount]
enabled = false
mountFsTab = true
"@

# Write the config
Write-Host "`nWriting new configuration..." -ForegroundColor Green
wsl -d $DistributionName -u root bash -c "echo '$desiredConfig' > /etc/wsl.conf"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Successfully configured wsl.conf" -ForegroundColor Green
    Write-Host "`nIMPORTANT: Run 'wsl --shutdown' and restart WSL for changes to take effect" -ForegroundColor Yellow
} else {
    Write-Error "Failed to write wsl.conf"
    exit 1
}

