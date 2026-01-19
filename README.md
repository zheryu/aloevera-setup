# WinGet DSC Machine Provisioning

Automated Windows 11 workstation setup using WinGet DSC (Desired State Configuration).

## Features

- **Idempotent**: Run multiple times safely
- **WSL-Centric**: Automated Ubuntu installation and configuration
- **Non-Interactive**: No manual prompts during setup (except password)
- **Portable**: Git-tracked configuration for easy migration
- **Multi-Stage**: Handles reboots and prerequisites gracefully

## Quick Start

### Prerequisites

- Windows 11 (or Windows 10 with WSL support)
- PowerShell 5.0 or later
- Administrator privileges
- Internet connection

### Installation

1. **Clone this repository:**
   ```powershell
   git clone <your-repo-url> C:/projects/aloevera-setup
   cd C:/projects/aloevera-setup
   ```

2. **Configure your setup:**
   
   Edit the following files according to your needs:
   
   - `modules/vscode/extensions.txt` - Add your VS Code extensions (one per line)
   - `modules/wsl/wsl.conf` - Configure your WSL settings
   - `.config/apps/*.winget` - Add/remove applications by category
   - `.config/wsl-setup.winget` - Configure WSL and Ubuntu settings

3. **Run the bootstrap script as Administrator:**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\scripts\bootstrap.ps1
   ```

4. **Reboot if prompted** and re-run the script if needed.

## Project Structure

```
C:/projects/aloevera-setup/
├── .config/
│   ├── apps/
│   │   ├── development.winget    # Dev tools (VSCode, Git, Python, etc.)
│   │   ├── communication.winget  # Chat/video apps (Discord, Zoom, etc.)
│   │   ├── media.winget          # Media apps (VLC, Spotify, Steam)
│   │   └── productivity.winget   # Productivity tools (Chrome, Obsidian, etc.)
│   └── wsl-setup.winget          # WSL and Ubuntu configuration
├── scripts/
│   ├── bootstrap.ps1             # Main orchestrator (run this)
│   ├── install-wsl.ps1           # WSL prerequisites installer
│   └── setup-ubuntu.ps1          # Non-interactive Ubuntu setup
├── modules/
│   ├── vscode/
│   │   └── extensions.txt        # List of VS Code extensions
│   └── wsl/
│       └── wsl.conf              # WSL configuration template
├── logs/                          # Execution logs
├── .gitignore                     # Git exclusions
└── README.md                      # This file
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
- Spotify
- Steam

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
