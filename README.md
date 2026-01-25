# Aloevera Setup
Automated Windows 11 workstation setup using WinGet DSC (Desired State Configuration) for my personal machine.

## Features

- **PowerShell Module**: Installable and reusable across machines
- **Idempotent**: Run multiple times safely
- **WSL-Centric**: Automated Ubuntu installation and configuration
- **Modular**: Install only what you need (Apps, WSL, or both)
- **Portable**: Git-tracked configuration for easy migration

## Quick Start

### Prerequisites

- Windows 11 (build 19041+) or Windows 10 with WSL support
- **PowerShell 7.5+** (not Windows PowerShell 5.1)
- **WinGet 1.4.0+**
- Administrator privileges
- Internet connection

**Fresh machine?** Run [setup.ps1](setup.ps1) first to install PowerShell 7 and WinGet.

### Installation

1. **Clone this repository:**
   ```powershell
   git clone <your-repo-url> C:\Users\ericz\projects\aloevera-setup
   cd C:\Users\ericz\projects\aloevera-setup
   ```

2. **Install prerequisites (fresh machines only):**
   ```powershell
   # Run this in Windows PowerShell 5.1 (built-in)
   .\setup.ps1
   
   # Then close and open PowerShell 7
   ```

3. **Import the module:**
   ```powershell
   # Run this in PowerShell 7+
   Import-Module .\Install-Aloevera\Install-Aloevera.psd1 -Force
   ```

4. **Run the setup:**
   ```powershell
   # Full setup (recommended for first time)
   Aloe
   
   # Or be explicit
   Install-Aloevera
   
   # Or install specific components
   Install-Aloevera -Component Apps
   Install-Aloevera -Component WSL
   ```

5. **Customize configuration (optional):**
   
   After first run, edit files in `~/.aloe/` to customize:
   - `apps/*.winget` - Add/remove applications
   - `blocklist.txt` - Skip categories
   - `wsl-setup.winget` - WSL settings
   - `wsl.conf` - WSL configuration

6. **Reboot if prompted** and run again if needed.

> **Note:** Configuration files are automatically initialized to `~/.aloe/` on first run. Edit them there, not in the `.config/` directory (which contains templates only).

## Usage

### Available Commands

```powershell
# Full setup
Aloe                              # Short alias
Install-Aloevera                  # Full command name

# Component-specific
Install-Aloevera -Component Apps
Install-Aloevera -Component WSL

# Get help
Get-Help Install-Aloevera -Full
```

## Project Structure

```
aloevera-setup/
├── Install-Aloevera/             # PowerShell Module
│   ├── Install-Aloevera.psd1     # Module manifest
│   ├── Install-Aloevera.psm1     # Module loader
│   ├── Public/                   # Exported functions
│   │   └── Install-Aloevera.ps1  # Main entry point
│   ├── Private/                  # Internal functions
│   │   ├── Apps/                 # Application installation
│   │   │   ├── Install-AloeveraApps.ps1
│   │   │   └── Show-ManualInstallations.ps1
│   │   ├── Wsl/                  # WSL setup
│   │   │   ├── Install-AloeveraWSL.ps1
│   │   │   ├── Initialize-UbuntuUser.ps1
│   │   │   ├── Set-WslConfig.ps1
│   │   │   └── Set-WslFstab.ps1
│   │   ├── Common.ps1            # Utility functions
│   │   ├── Initialize-AloeveraConfig.ps1
│   │   └── Test-Prerequisites.ps1
│   └── README.md                 # Module documentation
├── .config/                      # Configuration templates
│   ├── apps/
│   │   ├── development.winget    # Dev tools (VSCode, Git, Python)
│   │   ├── communication.winget  # Chat/video (Discord, Zoom)
│   │   ├── media.winget          # Media (VLC, Steam)
│   │   ├── productivity.winget   # Productivity (Chrome, Obsidian)
│   │   ├── blocklist.txt         # Categories to skip
│   │   └── uninstallable.txt     # Apps requiring manual install
│   ├── wsl-setup.winget          # WSL and Ubuntu installation
│   └── wsl.conf                  # WSL configuration template
├── modules/
│   └── vscode/
│       └── extensions.txt        # VS Code extensions list
├── logs/                         # Execution logs
├── setup.ps1                     # Bootstrap (installs PS7 + WinGet)
├── Test-Module.ps1               # Module verification script
└── README.md                     # This file

User Configuration Directory (~/.aloe):
~/.aloe/
├── apps/                         # User's app configurations
│   ├── *.winget                  # Copied from .config/apps/
│   ├── blocklist.txt
│   └── uninstallable.txt
├── wsl-setup.winget              # User's WSL config
├── wsl.conf                      # User's WSL settings
└── README.md                     # Configuration guide
```

## What Gets Installed

### Applications (via WinGet)

**Development Tools** (`.config/apps/development.winget`):
- Visual Studio Code
- Git for Windows
- GitHub CLI
- Python 3.6
- TeXworks

**Communication** (`.config/apps/communication.winget`):
- WeChat
- Discord
- Zoom

**Media & Entertainment** (`.config/apps/media.winget`):
- VLC Media Player
- Steam
- Spotify (requires manual installation - see [Manual Installations](#manual-installations))

**Productivity** (`.config/apps/productivity.winget`):
- Google Chrome
- Obsidian
- WinRAR

**WSL Setup** (`.config/wsl-setup.winget`):
- Ubuntu (WSL)
- Custom WSL configuration
- Fstab drive mounting

### Configurations
- WSL with custom settings (from `~/.aloe/wsl.conf`)
- VS Code extensions inside WSL (from `modules/vscode/extensions.txt`)
- Fstab configured for built-in drives only

## Customization

### Adding Applications

Edit the appropriate category file in `~/.aloe/apps/` and add a new resource:

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: YourApp
  directives:
    description: Install Your Application
  settings:
    id: Publisher.AppName
    source: winget
    useLatest: true
```

Find package IDs using: `winget search "app name"`

**Available categories:**
- `development.winget` - IDEs, compilers, dev tools
- `communication.winget` - Chat, video conferencing
- `media.winget` - Music, video, gaming
- `productivity.winget` - Browsers, note-taking, utilities

### Installing Specific Categories

Use the module's component system:

```powershell
# Install only applications
Install-Aloevera -Component Apps

# Install only WSL
Install-Aloevera -Component WSL
```

### Adding VS Code Extensions

Edit `modules/vscode/extensions.txt` and add extension IDs (one per line):

```
ms-python.python
ms-vscode.cpptools
eamodio.gitlens
```

Find extension IDs at https://marketplace.visualstudio.com/vscode or use `code --list-extensions`.

### Configuring WSL

Edit `~/.aloe/wsl.conf` with your desired WSL settings before running setup. Documentation: https://learn.microsoft.com/en-us/windows/wsl/wsl-config

Changes take effect after running `wsl --shutdown` and restarting WSL.

## Manual Installations

Some applications cannot be installed via automated provisioning and require manual installation. After running `Install-Aloevera`, the module will display a list of these applications with download URLs.

The list is maintained in `~/.aloe/apps/uninstallable.txt`. To add an app to this list:

```
AppName | https://download-url.com | Reason why automation isn't possible
```

## Troubleshooting

### Check Logs
All execution logs are saved in the `logs/` directory with timestamps.

### WSL Issues
- Verify WSL is installed: `wsl --status`
- List distributions: `wsl --list --verbose`
- Reset if needed: `wsl --unregister Ubuntu` (warning: deletes all data)

### Permission Issues
Always run PowerShell as Administrator when using `Install-Aloevera`.

### Re-running After Failure
The module is designed to be idempotent. Simply re-run `Install-Aloevera` after fixing any issues.

## Development Workflow

### Testing Changes
Test your configuration without actually applying it:
```powershell
# Test a specific category
winget configure test -f ~/.aloe/apps/development.winget

# Test WSL setup
winget configure test -f ~/.aloe/wsl-setup.winget
```

### Testing the Module
Run the module verification script:
```powershell
.\Test-Module.ps1
```

### Validating YAML
Use the YAML schema validation in VS Code or online YAML validators.

## Known Limitations

- Ubuntu user account is created non-interactively with prompted credentials
- WSL distribution name must be `Ubuntu` (default)
- First-time VS Code server initialization in WSL may take a few minutes
- Some Windows features may require a reboot to complete installation
- WinGet cannot update itself while running - handled separately by module

## Contributing

1. Test your changes on a fresh Windows installation (VM recommended)
2. Update documentation for any new features
3. Ensure all scripts maintain idempotency
4. Add appropriate error handling

## License

[Add your license here]

## References

- [WinGet Configuration Documentation](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)
- [WSL Documentation](https://learn.microsoft.com/en-us/windows/wsl/)
- [PowerShell DSC](https://learn.microsoft.com/en-us/powershell/dsc/overview)
