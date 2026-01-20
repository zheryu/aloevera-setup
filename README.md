# Install-Aloevera

Automated Windows 11 workstation setup using WinGet DSC (Desired State Configuration).

## Features

- **PowerShell Module**: Installable and reusable across machines
- **Idempotent**: Run multiple times safely
- **WSL-Centric**: Automated Ubuntu installation and configuration
- **Non-Interactive**: No manual prompts during setup
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

4. **Configure your setup:**
   
   Edit the following files according to your needs:
   
   - `.config/apps/*.winget` - Add/remove applications by category
   - `.config/apps/blocklist.txt` - Categories to skip
   - `.config/wsl-setup.winget` - WSL and Ubuntu settings
   - `modules/vscode/extensions.txt` - VS Code extensions
   - `modules/wsl/wsl.conf` - WSL configuration

5. **Run the setup:**
   ```powershell
   # Full setup (recommended for first time)
   Aloe
   
   # Or be explicit
   Install-Aloevera
   
   # Or install specific components
   Install-Aloevera -Component Apps
   Install-Aloevera -Component WSL
   ```

6. **Reboot if prompted** and run again if needed.

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

### Legacy Bootstrap Script

The original bootstrap script is still available for backwards compatibility:

```powershell
.\scripts\bootstrap.ps1
```

## Project Structure

```
aloevera-setup/
├── Install-Aloevera/             # PowerShell Module
│   ├── Install-Aloevera.psd1     # Module manifest
│   ├── Install-Aloevera.psm1     # Module loader
│   ├── Public/                   # Exported functions
│   │   ├── Install-Aloevera.ps1
│   │   ├── Install-AloeVeraApps.ps1
│   │   └── Install-AloeVeraWSL.ps1
│   ├── Private/                  # Internal functions
│   │   ├── Common.ps1            # Utility functions
│   │   └── Test-Prerequisites.ps1
│   └── README.md                 # Module documentation
├── .config/
│   ├── apps/
│   │   ├── development.winget    # Dev tools (VSCode, Git, Python)
│   │   ├── communication.winget  # Chat/video (Discord, Zoom)
│   │   ├── media.winget          # Media (VLC, Spotify, Steam)
│   │   ├── productivity.winget   # Productivity (Chrome, Obsidian)
│   │   └── blocklist.txt         # Categories to skip
│   └── wsl-setup.winget          # WSL and Ubuntu configuration
├── scripts/                      # Legacy scripts (still functional)
│   ├── bootstrap.ps1             # Original orchestrator
│   ├── Common.ps1                # Shared utilities
│   └── wsl/                      # WSL helper scripts
├── modules/
│   ├── vscode/
│   │   └── extensions.txt        # VS Code extensions list
│   └── wsl/
│       └── wsl.conf              # WSL configuration template
├── logs/                         # Execution logs
└── README.md                     # This file
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
- WSL with custom settings (from `modules/wsl/wsl.conf`)
- VS Code extensions inside WSL (from `modules/vscode/extensions.txt`)
- Git global configuration (username and email)

## Customization

### Adding Applications

Edit the appropriate category file in `.config/apps/` and add a new resource:

```yaml
- resource: Microsoft.WinGet.DSC/WinGetPackage
  id: YourApp
  directives:
    description: Install Your Application
  settings:
    id: Publisher.AppName
    source: winget
```

Find package IDs using: `winget search "app name"`

**Available categories:**
- `development.winget` - IDEs, compilers, dev tools
- `communication.winget` - Chat, video conferencing
- `media.winget` - Music, video, gaming
- `productivity.winget` - Browsers, note-taking, utilities

### Installing Specific Categories

You can run individual category configurations:

```powershell
# Install only development tools
winget configure -f .config/apps/development.winget --accept-configuration-agreements

# Install only media apps
winget configure -f .config/apps/media.winget --accept-configuration-agreements
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

Edit `modules/wsl/wsl.conf` with your desired WSL settings. Documentation: https://learn.microsoft.com/en-us/windows/wsl/wsl-config

## Manual Installations

Some applications cannot be installed via automated provisioning and require manual installation. After running [bootstrap.ps1](scripts/bootstrap.ps1), the script will display a list of these applications with download URLs.

You can also view this list anytime by running:
```powershell
.\scripts\show-manual-installs.ps1
```

The list is maintained in [.config/apps/uninstallable.txt](.config/apps/uninstallable.txt). To add an app to this list:

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
Always run `bootstrap.ps1` as Administrator.

### Re-running After Failure
The scripts are designed to be idempotent. Simply re-run `bootstrap.ps1` after fixing any issues.

## Development Workflow

### Testing Changes
Test your configuration without actually applying it:
```powershell
# Test a specific category
winget configure test -f .config/apps/development.winget

# Test WSL setup
winget configure test -f .config/wsl-setup.winget
```

### Validating YAML
Use the YAML schema validation in VS Code or online YAML validators.

### Adding New Scripts
Create new PowerShell scripts in the `scripts/` directory and call them from `bootstrap.ps1`.

## Known Limitations

- Password must be entered interactively during Ubuntu setup (security requirement)
- WSL distribution name may vary (`Ubuntu` vs `Ubuntu-22.04`) - check with `wsl --list`
- First-time VS Code server initialization in WSL may take a few minutes
- Some Windows features may require a reboot to complete installation

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
