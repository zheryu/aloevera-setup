This **Project Specification** is designed to be handed to an AI agent (like GitHub Copilot, Cursor, or ChatGPT) to build out your automated Windows workstation setup.

---

# Project Spec: WinGet DSC Machine Provisioning

## 1. Overview

The goal is to create a reproducible, declarative system to provision a Windows 11 machine. The system will leverage **WinGet Configuration (DSC)** to install applications, configure Windows settings, and initialize a highly customized **WSL (Windows Subsystem for Linux)** environment.

### Key Objectives

* **Idempotency:** Running the setup multiple times should result in the same state without errors.
* **WSL-Centric:** Automated installation of Ubuntu, disabling drive automounting, and installing extensions into the WSL VS Code server.
* **Portability:** The entire project resides in a Git-tracked folder on the Windows filesystem (`C:/projects/aloevera-setup`) for easy migration.

---

## 2. Project Structure

The agent should organize the files as follows to balance modularity with WinGet's current engine capabilities.

```text
C:/projects/aloevera-setup/
├── .config/
│   └── configuration.winget      # Master YAML Configuration
├── scripts/
│   ├── bootstrap.ps1             # One-click entry point for new machines
│   └── wsl-setup.ps1             # Helper for internal WSL logic
├── modules/
│   ├── vscode/
│   │   └── extensions.txt        # List of extensions for AI to parse
│   └── wsl/
│       └── wsl.conf              # Source file for WSL settings
└── .gitignore

```

---

## 3. Core Configuration (`configuration.winget`)

The agent should use the **Schema 0.2** format. This file serves as the "source of truth."

```yaml
# yaml-language-server: $schema=https://aka.ms/configuration-dsc-schema/0.2
properties:
  configurationVersion: 0.2.0
  resources:
    # --- Infrastructure Layer ---
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: VSCode
      directives:
        description: Install Visual Studio Code
      settings:
        id: Microsoft.VisualStudioCode
        source: winget

    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: Git
      directives:
        description: Install Git for Windows
      settings:
        id: Git.Git
        source: winget

    # --- WSL Layer ---
    - resource: Microsoft.WinGet.DSC/WinGetPackage
      id: Ubuntu
      directives:
        description: Install Ubuntu Distro
      settings:
        id: Canonical.Ubuntu.2204
        source: winget

    - resource: PSDSC/Script
      id: WSLConfig
      dependsOn: [Ubuntu]
      directives:
        description: Disable Automounting in WSL
      settings:
        GetScript: |
          return @{ Result = "Checking WSL Config" }
        TestScript: |
          $val = wsl -d Ubuntu cat /etc/wsl.conf
          return $val -match "enabled\s*=\s*false"
        SetScript: |
          $content = "[automount]`nenabled=false"
          wsl -d Ubuntu sh -c "echo '$content' > /etc/wsl.conf"

    # --- VS Code Extensions (WSL Side) ---
    - resource: PSDSC/Script
      id: VSCodeWSLExtensions
      dependsOn: [VSCode, Ubuntu]
      directives:
        description: Install Dev Extensions inside WSL
      settings:
        GetScript: |
          return @{ Result = "Checking WSL Extensions" }
        TestScript: |
          $list = wsl -d Ubuntu -- code --list-extensions
          return $list -contains "ms-python.python"
        SetScript: |
          wsl -d Ubuntu -- code --install-extension ms-python.python
          wsl -d Ubuntu -- code --install-extension ms-vscode.cpptools

```

---

## 4. Bootstrap Script (`bootstrap.ps1`)

This script is what you run on a brand-new computer to get the ball rolling.

```powershell
# Check for Admin Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit
}

# 1. Ensure WinGet is up to date
Write-Host "Updating WinGet..." -ForegroundColor Cyan
winget update --all

# 2. Run the Configuration
Write-Host "Applying Machine State..." -ForegroundColor Cyan
winget configure -f "C:/projects/aloevera-setup/.config/configuration.winget" --accept-configuration-agreements

```

---

## 5. Development Workflow for the AI Agent

When asking your agent to update this system, use the following prompts:

* **To add an app:** *"Add [App Name] to the configuration.winget file. Find the correct WinGet ID first."*
* **To add a setting:** *"Create a PSDSC/Registry resource in configuration.winget to set the Taskbar alignment to the left."*
* **To update WSL:** *"Modify the WSL Script resource to also set the default user to my username."*

---

## 6. Execution Instructions

1. **Clone** this repo to `C:/projects/aloevera-setup`.
2. **Open** PowerShell as Administrator.
3. **Run** `.\scripts\bootstrap.ps1`.
4. **Reboot** when prompted to finalize WSL and system features.