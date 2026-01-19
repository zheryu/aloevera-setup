# Copyright (c) 2026. All rights reserved.
# Licensed under the MIT License.

enum Ensure {
    Absent
    Present
}

<#
.SYNOPSIS
    DSC Resource to configure WSL settings via wsl.conf
.DESCRIPTION
    This resource manages the /etc/wsl.conf file in the specified WSL distribution.
    It can configure automount settings and other WSL-specific configurations.
#>
[DSCResource()]
class WSLConfig {
    [DscProperty(Key)]
    [string]$DistributionName

    [DscProperty()]
    [bool]$AutoMountEnabled = $false

    [DscProperty()]
    [bool]$MountFsTab = $true

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [WSLConfig] Get() {
        $currentState = [WSLConfig]::new()
        $currentState.DistributionName = $this.DistributionName

        # Check if distribution exists
        $distros = wsl --list --quiet 2>$null
        if ($distros -notcontains $this.DistributionName) {
            $currentState.Ensure = [Ensure]::Absent
            return $currentState
        }

        # Read current wsl.conf
        $wslConfContent = wsl -d $this.DistributionName -u root cat /etc/wsl.conf 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($wslConfContent)) {
            $currentState.Ensure = [Ensure]::Absent
            return $currentState
        }

        # Parse the content
        $currentState.Ensure = [Ensure]::Present
        if ($wslConfContent -match 'enabled\s*=\s*true') {
            $currentState.AutoMountEnabled = $true
        } elseif ($wslConfContent -match 'enabled\s*=\s*false') {
            $currentState.AutoMountEnabled = $false
        }

        if ($wslConfContent -match 'mountFsTab\s*=\s*true') {
            $currentState.MountFsTab = $true
        } elseif ($wslConfContent -match 'mountFsTab\s*=\s*false') {
            $currentState.MountFsTab = $false
        }

        return $currentState
    }

    [bool] Test() {
        $currentState = $this.Get()

        if ($this.Ensure -ne $currentState.Ensure) {
            return $false
        }

        if ($this.Ensure -eq [Ensure]::Absent) {
            return $true
        }

        return ($this.AutoMountEnabled -eq $currentState.AutoMountEnabled) -and
               ($this.MountFsTab -eq $currentState.MountFsTab)
    }

    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Absent) {
            wsl -d $this.DistributionName -u root rm -f /etc/wsl.conf
            Write-Host "Removed wsl.conf from $($this.DistributionName)"
            return
        }

        $configContent = @"
[automount]
enabled = $($this.AutoMountEnabled.ToString().ToLower())
mountFsTab = $($this.MountFsTab.ToString().ToLower())
"@

        # Write the config using wsl command
        $escapedContent = $configContent -replace '"', '\"'
        wsl -d $this.DistributionName -u root bash -c "echo '$escapedContent' > /etc/wsl.conf"
        
        Write-Host "Updated wsl.conf for $($this.DistributionName). Restart WSL for changes to take effect: wsl --shutdown"
    }
}

<#
.SYNOPSIS
    DSC Resource to configure WSL fstab
.DESCRIPTION
    This resource manages the /etc/fstab file in the specified WSL distribution.
    It can configure drive mounts and other filesystem mount options.
#>
[DSCResource()]
class WSLFstab {
    [DscProperty(Key)]
    [string]$DistributionName

    [DscProperty()]
    [string[]]$MountPoints = @()

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [WSLFstab] Get() {
        $currentState = [WSLFstab]::new()
        $currentState.DistributionName = $this.DistributionName

        # Check if distribution exists
        $distros = wsl --list --quiet 2>$null
        if ($distros -notcontains $this.DistributionName) {
            $currentState.Ensure = [Ensure]::Absent
            return $currentState
        }

        # Read current fstab
        $fstabContent = wsl -d $this.DistributionName -u root cat /etc/fstab 2>$null
        if ($LASTEXITCODE -ne 0) {
            $currentState.Ensure = [Ensure]::Absent
            return $currentState
        }

        $currentState.Ensure = [Ensure]::Present
        $currentState.MountPoints = @()
        
        # Parse mount points
        $lines = $fstabContent -split "`n" | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' }
        foreach ($line in $lines) {
            $currentState.MountPoints += $line.Trim()
        }

        return $currentState
    }

    [bool] Test() {
        $currentState = $this.Get()

        if ($this.Ensure -ne $currentState.Ensure) {
            return $false
        }

        if ($this.Ensure -eq [Ensure]::Absent) {
            return $true
        }

        # Check if all desired mount points are present
        foreach ($mountPoint in $this.MountPoints) {
            $found = $false
            foreach ($currentMount in $currentState.MountPoints) {
                if ($currentMount -like "*$mountPoint*") {
                    $found = $true
                    break
                }
            }
            if (-not $found) {
                return $false
            }
        }

        return $true
    }

    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Absent) {
            wsl -d $this.DistributionName -u root bash -c "echo '' > /etc/fstab"
            Write-Host "Cleared fstab for $($this.DistributionName)"
            return
        }

        $fstabContent = "# Configured by WSL.Dsc`n"
        foreach ($mountPoint in $this.MountPoints) {
            $fstabContent += "$mountPoint`n"
        }

        # Write the fstab using wsl command
        $escapedContent = $fstabContent -replace '"', '\"'
        wsl -d $this.DistributionName -u root bash -c "echo '$escapedContent' > /etc/fstab"
        
        Write-Host "Updated fstab for $($this.DistributionName)"
    }
}
