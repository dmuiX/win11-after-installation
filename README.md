# Windows 11 Post-Install Setup

Automated setup script to configure Windows 11, install essential software, apply privacy tweaks, and set up development tools.

## 🚀 Quick Start

1.  Clone this repository.
2.  Run **`win11-post-setup.bat`** as Administrator.
3.  Follow the on-screen prompts (if any).

## ✨ Features

*   **Package Management**: Installs software via `winget` (Firefox, VS Code, Git, etc.).
*   **Privacy & Security**: Disables Telemetry, Advertising ID, Location Tracking, and Start Menu ads.
*   **System Maintenance**:
    *   **Daily Updates**: Auto-schedules a silent daily `winget upgrade` (pins AppInstaller to avoid dependency loops).
    *   **Weekly Cleanup**: Auto-schedules a deep system cleanup (Temp files, Update cache, DNS) every week. *Note: Safely preserves your Downloads folder and Recycle Bin.*
*   **Customization**:
    *   Installs **MesloLGS NF** font (idempotent, only installs if missing).
    *   Configures **AutoHotkey** shortcuts for macOS-like keybindings.
    *   Applies Dark Theme and Taskbar preferences (Left alignment).
    *   **SSH Agent**: Automatically enables and starts the Windows OpenSSH Agent service.

## 🔄 VS Code Settings Sync

This repo acts as specific "Restore Point" for your VS Code configuration.

### How to Backup
Run `helpers\backup-settings.bat`.
This will export your currently installed extensions list, `settings.json`, and `keybindings.json` to the `vscode-config/` folder in this repo.
**Commit and push these files to your git repository.**

### How to Restore
When you run `win11-post-setup.bat` on a new machine, it acts intelligently:
*   It checks if `vscode-config/` exists.
*   If found, it automatically **restores** your settings and **installs** all your extensions.

## 📂 Scripts Overview (in `helpers/`)

*   `cleanup-win.bat`: Performs advanced system maintenance (DISM, SFC, Disk Cleanup).
*   `daily-update.bat`: Handles silent daily package updates.
*   `backup-settings.bat`: Snapshots your VS Code config to the repo.
*   `macos-hotkeys.ahk`: AutoHotkey script definition for keyboard shortcuts.
