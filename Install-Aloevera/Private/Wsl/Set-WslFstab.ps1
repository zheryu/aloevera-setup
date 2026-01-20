function Set-WslFstab {
    <#
    .SYNOPSIS
        Configures WSL fstab to allowlist only built-in drives.

    .DESCRIPTION
        Prevents external drives from auto-mounting in WSL by configuring
        /etc/fstab to only mount specified drives.

    .PARAMETER DistributionName
        Name of the WSL distribution to configure. Default: Ubuntu

    .PARAMETER AdditionalDrives
        Additional drive letters to include beyond detected built-in drives.

    .EXAMPLE
        Set-WslFstab
        Set-WslFstab -DistributionName Ubuntu-22.04
        Set-WslFstab -AdditionalDrives @('D', 'E')
    #>

    param(
        [Parameter()]
        [string]$DistributionName = 'Ubuntu',
        
        [Parameter()]
        [string[]]$AdditionalDrives = @()
    )

    Write-Host "Configuring fstab for $DistributionName..." -ForegroundColor Cyan

    # Check if distribution exists
    $distros = wsl --list --quiet 2>$null
    if ($distros -notcontains $DistributionName) {
        Write-Error "Distribution '$DistributionName' not found. Available: $($distros -join ', ')"
        return 1
    }

    # Get current fstab
    $currentFstab = wsl -d $DistributionName -u root cat /etc/fstab 2>$null

    Write-Host "Current fstab content:" -ForegroundColor Yellow
    if ($currentFstab) {
        Write-Host $currentFstab
    } else {
        Write-Host "(file does not exist)"
    }

    # Get list of local fixed drives (Type 3 = Local Disk)
    $builtInDrives = Get-CimInstance Win32_LogicalDisk | 
        Where-Object { $_.DriveType -eq 3 } | 
        Select-Object -ExpandProperty DeviceID |
        ForEach-Object { $_.TrimEnd(':') }

    Write-Host "`nDetected built-in drives: $($builtInDrives -join ', ')" -ForegroundColor Cyan

    # Combine with additional drives if specified
    $allDrives = $builtInDrives + $AdditionalDrives | Select-Object -Unique

    # Build fstab content
    $fstabLines = @(
        "# Configured by aloevera-setup - Built-in drives only",
        "# <device>  <mount point>  <type>  <options>  <dump>  <pass>"
    )

    foreach ($drive in $allDrives) {
        $driveLetter = $drive.ToUpper()
        $mountPoint = "/mnt/$($drive.ToLower())"
        # Use 'optional' flag so missing drives don't cause boot issues
        $fstabLines += "${driveLetter}: $mountPoint drvfs defaults,optional 0 0"
    }

    $fstabContent = $fstabLines -join "`n"

    # Write the fstab
    Write-Host "`nWriting new fstab..." -ForegroundColor Green
    wsl -d $DistributionName -u root bash -c "echo '$fstabContent' > /etc/fstab"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Successfully configured fstab with drives: $($allDrives -join ', ')" -ForegroundColor Green
        return 0
    } else {
        Write-Error "Failed to write fstab"
        return 1
    }
}
