# 🖥️ Win11 VM Resume

Automatic suspend/wake management for a Windows 11 VM via RDP connections. The VM suspends when you disconnect from RDP and wakes when you reconnect.

## ✨ Overview

This setup creates a seamless experience where:
- 🔌 **Connecting via RDP** → Automatically wakes/resumes the suspended VM
- 💤 **Disconnecting from RDP** → Automatically suspends the VM to save resources

## 🧩 Components

### 🐧 Linux Host (`setup-rdp-wake.sh`)

Sets up a systemd socket service that:
- 👂 Listens on port **33899** for incoming RDP connections
- ⏰ Wakes/resumes the Win11 VM via `virsh`
- ⏳ Waits for the VM's RDP port (3389) to become available
- 🔀 Proxies the connection to the VM using `socat`

**Dependencies:** `socat`, `nc` (netcat), `virsh` (libvirt)

### 🪟 Windows Guest (`setup-auto-suspend.ps1`)

Creates a scheduled task that:
- 🎯 Triggers on RDP disconnect (Event ID 24)
- 📡 SSHs back to the Linux host to suspend the VM

**Requirements:** PowerShell 7, SSH key authentication to Linux host

## 🚀 Installation

### 1️⃣ Linux Host

```bash
# Run as root (auto-elevates)
./setup-rdp-wake.sh
```

This creates:
- `/usr/local/bin/rdp-wake-wrapper.sh` – Wake logic and connection proxy
- `/etc/systemd/system/rdp-wake.socket` – Listens on port 33899
- `/etc/systemd/system/rdp-wake@.service` – Handles each connection

### 2️⃣ Windows Guest

```powershell
# Run as Administrator (auto-elevates)
.\setup-auto-suspend.ps1
```

This creates:
- `C:\ProgramData\rdp-suspend.ps1` – Suspend script
- Scheduled task **AutoSuspend-RDP** – Fires on RDP disconnect

## ⚙️ Configuration

Edit the configuration variables in each script:

**setup-rdp-wake.sh:**
```bash
IP="192.168.1.13"      # Windows VM IP
PORT="3389"            # RDP port
```

**setup-auto-suspend.ps1:**
```powershell
$LinuxHost = "192.168.1.5"
$LinuxUser = "nasadmin"
$VMName = "Win11"
```

## 🎮 Usage

Connect to RDP via the Linux host's listening port:

```
mstsc /v:192.168.1.5:33899
```

Or configure your RDP client to connect to `<Linux-Host-IP>:33899`.

## 🔧 Troubleshooting

Check the service status on Linux:
```bash
systemctl status rdp-wake.socket
journalctl -u rdp-wake@* -f
```

Verify the port is listening:
```bash
ss -tlnp | grep 33899
```

---

Made with ❤️ for lazy VM management
