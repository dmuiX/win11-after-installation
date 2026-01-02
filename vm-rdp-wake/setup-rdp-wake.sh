#!/bin/bash
set -e

# Auto-elevate to root if not already
if [ "$EUID" -ne 0 ]; then
    echo ">>> Elevating to root..."
    exec sudo "$0" "$@"
fi

echo ">>> Starting RDP Wake Repair (Unified Wrapper Method)..."

# 1. Verify Dependencies
if ! command -v socat &> /dev/null; then
    echo "ERROR: 'socat' is not installed."
    exit 1
fi
if ! command -v nc &> /dev/null; then
    echo "ERROR: 'nc' (netcat) is not installed."
    exit 1
fi

# 2. Write Unified Wrapper Script
# This script handles logging AND data piping correctly preventing RDP corruption.
echo ">>> Deploying /usr/local/bin/rdp-wake-wrapper.sh..."
cat << 'EOF' > /usr/local/bin/rdp-wake-wrapper.sh
#!/bin/bash

# --- FILE DESCRIPTOR MAGIC ---
# FD 0 (Stdin)  = The Connected Socket (Data from Client)
# FD 1 (Stdout) = The Connected Socket (Data to Client)
# FD 2 (Stderr) = System Log (Journal)

# 1. Save the Socket (Stdout) to FD 3 so we can use it later
exec 3>&1

# 2. Redirect standard 'echo' output to Stderr (Log) 
#    so we don't send text "DEBUG:..." to the RDP Client (which corrupts the connection)
exec 1>&2

echo "Wrapper: Starting RDP Wake Sequence..."

# --- WAKE LOGIC ---
if [ -x "/usr/bin/virsh" ]; then VIRSH="/usr/bin/virsh"; else VIRSH=$(command -v virsh); fi

if [ -n "$VIRSH" ]; then
    echo "Wrapper: Checking VM state..."
    STATE=$($VIRSH domstate Win11 2>/dev/null || echo "unknown")
    
    case "$STATE" in
        running)
            echo "Wrapper: VM is already running."
            ;;
        paused)
            echo "Wrapper: VM is paused, resuming..."
            $VIRSH resume Win11 || echo "Wrapper: Warn - Failed to resume VM"
            ;;
        "shut off"|"")
            echo "Wrapper: VM is off, starting..."
            $VIRSH start Win11 || echo "Wrapper: Warn - Failed to start VM"
            ;;
        *)
            echo "Wrapper: Unknown state '$STATE', attempting start..."
            $VIRSH start Win11 || echo "Wrapper: Warn - Failed to start VM"
            ;;
    esac
else
    echo "Wrapper: Warn - virsh not found, skipping wake."
fi

IP="192.168.1.13"
PORT="3389"
echo "Wrapper: Waiting for port $IP:$PORT..."
# Wait loop
MAX=60
count=0
while ! nc -z -w 1 "$IP" "$PORT"; do
    echo "Wrapper: Port closed ($count)..."
    sleep 1
    count=$((count+1))
    if [ "$count" -ge "$MAX" ]; then
        echo "Wrapper: Timeout waiting for VM."
        exit 1
    fi
done

echo "Wrapper: Port Ready. Swapping FDs for Proxy..."

# --- HANDOVER ---

# 3. Restore the Socket to Stdout (from FD 3)
exec 1>&3
# 4. Close FD 3 (cleanup)
exec 3>&-

# 5. Hand over control to socat
#    socat inherits FD 0 (Input Socket) and FD 1 (Output Socket)
echo "Wrapper: Executing socat..." >&2
exec /usr/bin/socat STDIO "TCP:$IP:$PORT,retry=5"
EOF
chmod +x /usr/local/bin/rdp-wake-wrapper.sh
echo "✅ Wrapper created."

# 3. Write Socket File
echo ">>> Deploying /etc/systemd/system/rdp-wake.socket..."
cat <<EOF > /etc/systemd/system/rdp-wake.socket
[Unit]
Description=RDP Wake Socket

[Socket]
ListenStream=33899
Accept=yes
TriggerLimitIntervalSec=0

[Install]
WantedBy=sockets.target
EOF

# 4. Write Service Template (Simplified)
echo ">>> Deploying /etc/systemd/system/rdp-wake@.service..."
cat <<EOF > /etc/systemd/system/rdp-wake@.service
[Unit]
Description=Resume Win11 & Proxy RDP (Instance %i)
Requires=rdp-wake.socket

[Service]
Type=simple
# The wrapper handles everything: Logs to Journal, Data to Socket
ExecStart=/usr/local/bin/rdp-wake-wrapper.sh
StandardInput=socket
StandardOutput=socket
StandardError=journal
TimeoutStartSec=120
EOF

# 5. Reload and Restart
echo ">>> Reloading Systemd..."
systemctl stop rdp-wake.socket 2>/dev/null || true
systemctl daemon-reload
systemctl reset-failed

echo ">>> Starting Socket..."
systemctl enable --now rdp-wake.socket

echo
echo "=== Deployment Status ==="
echo
for f in /usr/local/bin/rdp-wake-wrapper.sh /etc/systemd/system/rdp-wake.socket /etc/systemd/system/rdp-wake@.service; do
    if [ -f "$f" ]; then
        MOD=$(stat -c "%y" "$f" 2>/dev/null | cut -d'.' -f1)
        echo "✅ $f (modified: $MOD)"
        echo "--- Contents: ---"
        cat "$f"
        echo
        echo "-----------------"
        echo
    else
        echo "❌ $f (not found)"
    fi
done
echo
systemctl is-enabled rdp-wake.socket &>/dev/null && echo "✅ rdp-wake.socket: enabled" || echo "❌ rdp-wake.socket: not enabled"
systemctl is-active rdp-wake.socket &>/dev/null && echo "✅ rdp-wake.socket: active" || echo "❌ rdp-wake.socket: not active"
echo
echo "=== Listening Port ==="
ss -tlnp 2>/dev/null | grep 33899 || echo "❌ Port 33899 not listening"
echo
echo ">>> DONE."
