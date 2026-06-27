# 🖥️✨ Windows 11 Post-Install Setup 🚀💻

🤖 Automated PowerShell 7 script to configure Windows 11, install essential software, apply privacy tweaks, and set up a full development environment—beautifully! ✨

---

## 🚀 Quick Start

1. 📥 Clone this repository
2. ▶️ Run **`win11-post-setup.bat`** as Administrator (it will bootstrap PowerShell 7 if needed)
3. ☕ Sit back and relax—everything is automated! 🎉

---

## ✨ Features

### 📦 Package Management
Installs 20+ packages via `winget` in a single pass:
- 🌐 **Browsers**: Firefox
- 💻 **Terminals**: Clink, Starship prompt
- 🛠️ **Dev Tools**: VS Code Insiders, Git (incl. Vim), gsudo, Delta (git pager)
- 🔧 **Utils**: 7-Zip, TeraCopy, TreeSize, OpenHashTab, aria2
- 🔤 **Fonts**: JetBrains Mono NF, MesloLGS NF (Powerlevel10k)
- 💾 **Backup**: Veeam Agent, MailStore Home
- 🔍 **AI**: Perplexity
- 🎮 **Other**: Steam, Google Drive, iCloud, VcXsrv (X server), AutoHotkey

### 🔒 Privacy & Security
- 🚫 Disables **Telemetry**, **Advertising ID**, and **Location Tracking**
- 🗑️ Removes **Start Menu ads** and **Cortana/Bing** integration
- 🛡️ Restricts typing & contacts harvesting

### 🧹 System Maintenance
- 📅 **Daily Updates**: Silent scheduled `winget upgrade` (pins AppInstaller to avoid dependency loops)
- 🗓️ **Weekly Cleanup**: Deep system cleanup (Disk Cleanup, DISM, SFC)
- ✅ *Safely preserves Downloads folder & Recycle Bin* 📁

### 🎨 Customization
- 🌈 **Starship prompt** with Gruvbox Rainbow preset
- ⌨️ **Clink** integration with custom aliases (`ls`, `ll`, `vi`, `cat`)
- 🌙 **Dark Theme**
- 🍎 **macOS-like** keyboard shortcuts via AutoHotkey
- 📝 **.vimrc** with vim-plug and plugins
- 🖼️ **X11 Forwarding** via VcXsrv with auto-configured DISPLAY variable

### 🔧 Developer Tools
- 🔀 **Git** with Delta pager & auto-configured global settings
- 🔑 **SSH Agent** enabled and auto-started

### 🧼 Debloater
🧹 Automatically launches the popular [Win11Debloat](https://win11debloat.raphi.re/) script for bloatware removal! 💪

---

## 🔄 VS Code Settings Sync

📂 This repo doubles as a portable **Restore Point** for your VS Code configuration.

### 💾 Backup
```batch
.\helpers\backup-settings.ps1
```
📤 Exports your installed extensions, `settings.json`, and `keybindings.json` to `vscode-config/`.
**✨ Commit and push these files to save your setup!**

### ♻️ Restore
When you run `win11-post-setup.bat` on a fresh machine:
- 🔍 It detects if `vscode-config/` exists
- ⬇️ Restores settings and installs all extensions automatically

---

## 📂 Directory Structure

```
.
├── 📁 configs/                  # 🔧 Portable configuration files
│   ├── 📝 .vimrc               # Vim configuration
│   ├── 📝 aliases              # Clink shell aliases
│   ├── 🌐 clink_display.lua    # X11 DISPLAY variable setup
│   ├── 🧹 cleanup-win.bat      # Weekly cleanup script
│   ├── 🔄 daily-update.ps1     # Daily winget update script
│   ├── ⌨️ macos-hotkeys.ahk    # AutoHotkey keybindings
│   └── 🎮 manage-gpu.bat       # GPU management utility
│
├── 📁 helpers/                  # 🛠️ Operational scripts
│   ├── 💾 backup-settings.ps1  # VS Code backup
│   └── ♻️ restore-settings.ps1 # VS Code restore
│
├── 📁 vscode-config/           # 💻 VS Code portable config
│
├── 📁 archive/                 # 📦 Legacy & extras
│
├── 🚀 win11-post-setup.bat     # ▶️ Entry point (run this!)
└── ⚡ win11-post-setup.ps1     # Main PowerShell 7 script
```

---

## 💤 VM Auto-Suspend/Wake

> [!NOTE]
> 🐧 The RDP suspend/wake automation is now **fully handled on the Linux host** and is no
> longer part of this repo. The Windows guest no longer creates a suspend scheduled task.

---

## 🔁 Idempotent Design

🛡️ This script is **safe to run multiple times**! All expensive operations (package installs, font downloads) check existing state before executing. 🔍 Config files are intentionally refreshed each run to stay in sync with the repo. ✅

---

## 🛠️ Requirements

- 🪟 **Windows 11** (22H2 or later recommended)
- 📦 **winget** (ships with Windows 11)
- 👑 **Administrator privileges**

> [!NOTE]
> ⚡ PowerShell 7 is **automatically installed** if not present.

---

## 📜 License

MIT — Do whatever you want! 🎉 Contributions welcome! 🤝💖
