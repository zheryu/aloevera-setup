# Bootstrap.ps1 → Install-Aloevera Migration Checklist

This checklist tracks functionality from `bootstrap.ps1` that needs to be integrated into the modularized `Install-Aloevera` module.

## Critical Missing Features

- [x] **WinGet Self-Update**
  - Location: Stage 2 in bootstrap.ps1 (lines 76-85)
  - Functionality: Updates WinGet itself before running installations
  - Command: `winget upgrade --id Microsoft.DesktopAppInstaller --accept-source-agreements --silent`
  - Integration Target: ~~`Test-Prerequisites.ps1` or new `Update-WinGet` private function~~
  - **✅ COMPLETED**: Moved to `setup.ps1` bootstrap script. Module now assumes prerequisites are met.
  - **Design Change**: Module validates, doesn't install. `setup.ps1` handles PS7 + WinGet installation.

- [x] **Ubuntu Non-Interactive Setup**
  - Location: Stage 3 in bootstrap.ps1 (lines 88-90)
  - Functionality: Calls `setup-ubuntu.ps1` to configure Ubuntu after installation
  - Integration Target: `Install-AloeveraWSL.ps1` - add after Ubuntu installation
  - **✅ COMPLETED**: Implemented in `Private/Initialize-UbuntuUser.ps1`, integrated into `Install-AloeveraWSL.ps1` as step 3/5

- [x] **Manual Installations Report**
  - Location: End of bootstrap.ps1 (line 119)
  - Functionality: Calls `show-manual-installs.ps1` to display apps requiring manual steps
  - Integration Target: `Install-Aloevera.ps1` - show at end of full setup
  - **✅ COMPLETED**: Implemented in `Private/Show-ManualInstallations.ps1`, called at end of `Install-Aloevera.ps1`

- [x] **Success Summary with Next Steps**
  - Location: Lines 122-132 in bootstrap.ps1
  - Functionality: Shows detailed post-installation guidance:
    - Log file location
    - Reboot reminder
    - WSL verification command: `wsl --list --verbose`
    - Git config reminder: `git config --global user.name/email`
  - Integration Target: `Install-Aloevera.ps1` - replace simple success message
  - **✅ COMPLETED**: Enhanced success/error banners with context-aware next steps in `Install-Aloevera.ps1`

## Nice to Have Features

- [x] **Enhanced Error/Success Banners**
  - Location: Throughout bootstrap.ps1
  - Functionality: Uses `Write-ErrorBanner` and `Write-SuccessBanner` for visual clarity
  - Current State: Install-Aloevera uses basic messages
  - Integration Target: Update error handling in `Install-Aloevera.ps1`
  - **✅ COMPLETED**: Already implemented with success summary

- [x] **Pre-flight Configuration File Validation**
  - Location: Line 97 in bootstrap.ps1
  - Functionality: Explicitly checks if wsl-setup.winget exists before running
  - Current State: Install-AloeveraWSL warns but continues
  - Integration Target: `Install-AloeveraWSL.ps1` - throw error if config missing
  - **✅ COMPLETED**: Now throws error with helpful message if wsl-setup.winget is missing

## Already Implemented ✓

- [x] Logging with timestamps
- [x] Prerequisite validation (OS, PowerShell, internet, WinGet)
- [x] Component-based installation (Apps, WSL)
- [x] Error handling with try/catch/finally
- [x] Administrator requirement
- [x] Stage-based execution flow
- [x] Transcript logging

## Script Dependencies to Review

- `scripts/setup-ubuntu.ps1` - Non-interactive Ubuntu configuration
- `scripts/show-manual-installs.ps1` - Manual installation reporting
- `scripts/wsl/wslconfig.ps1` - WSL configuration (already integrated)
- `scripts/wsl/wslfstab.ps1` - fstab configuration (already integrated)

## Notes

- Bootstrap.ps1 can be kept for backwards compatibility
- Focus on integrating core functionality into module first
- Visual improvements (banners) are lower priority
- Documentation updates needed after integration
