# Install-Aloevera PowerShell Module

Automated Windows 11 workstation setup using WinGet DSC (Desired State Configuration).

## Installation

### Option 1: Import from Local Path

```powershell
# Navigate to the module directory
cd C:\Users\ericz\projects\aloevera-setup\Install-Aloevera

# Import the module
Import-Module .\Install-Aloevera.psd1 -Force

# Verify it's loaded
Get-Module Install-Aloevera
```

### Option 2: Install to PowerShell Module Path

```powershell
# Copy module to user module directory
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\Install-Aloevera"
Copy-Item -Path "C:\Users\ericz\projects\aloevera-setup\Install-Aloevera" -Destination $modulePath -Recurse -Force

# Module will auto-load when you use the commands
```

## Usage

### Full Setup

Run the complete setup (WSL + Applications):

```powershell
Install-Aloevera
```

Or use the convenient alias:

```powershell
Aloe
```

### Component-Specific Setup

Install only specific components:

```powershell
# Install only applications
Install-Aloevera -Component Apps

# Install only WSL
Install-Aloevera -Component WSL

# Install both (explicit)
Install-Aloevera -Component Apps,WSL
```

### Skip Prerequisites Check

To skip prerequisite validation (use with caution):

```powershell
Install-Aloevera -SkipPrerequisites
```

## Prerequisites

The module will automatically check for:

- **OS Version**: Windows 10 build 19041+ or Windows 11
- **PowerShell Version**: 5.1 or later
- **Internet Connectivity**: Required for package downloads
- **WinGet**: Version 1.4.0+ (available from Microsoft Store)
- **Administrator Privileges**: Required for system modifications

## Configuration

Before running the setup, configure your preferences:

### Application Categories

Edit files in `.config/apps/` directory:

- `browsers.winget` - Web browsers
- `communication.winget` - Chat and communication tools
- `development.winget` - Development tools and IDEs
- `utilities.winget` - System utilities

Add categories to `blocklist.txt` to skip them:

```
gaming
entertainment
```

### WSL Configuration

- `.config/wsl-setup.winget` - Ubuntu installation settings
- `modules/wsl/wsl.conf` - WSL system configuration

## Logging

All operations are logged to the `logs/` directory with timestamps:

```
logs/aloevera-YYYYMMDD-HHmmss.log
```

## Help

Get detailed help for any command:

```powershell
Get-Help Install-Aloevera -Full
Get-Help Install-AloeVeraApps -Full
Get-Help Install-AloeVeraWSL -Full
```

## Module Structure

```
Install-Aloevera/
├── Install-Aloevera.psd1        # Module manifest
├── Install-Aloevera.psm1        # Main module loader
├── Public/                       # Exported functions
│   ├── Install-Aloevera.ps1
│   ├── Install-AloeVeraApps.ps1
│   └── Install-AloeVeraWSL.ps1
└── Private/                      # Internal functions
    ├── Common.ps1
    └── Test-Prerequisites.ps1
```

## Examples

### Fresh Machine Setup

```powershell
# Run full setup with all components
Aloe
```

### Developer Workstation

```powershell
# Install only development tools
Install-Aloevera -Component Apps
```

### WSL-Only Setup

```powershell
# Set up WSL without installing applications
Install-Aloevera -Component WSL
```

### Non-Interactive Mode

```powershell
# Skip all prompts
Install-AloeVeraApps -SkipPrompt
```

## Notes

- Run PowerShell as Administrator
- First-time WSL installation may require a reboot
- Logs are automatically created for troubleshooting
- Configuration files use YAML format (WinGet DSC)
