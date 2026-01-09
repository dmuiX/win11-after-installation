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

# --- WAKE LOGIC (no locking needed - virsh operations are idempotent) ---
if [ -x "/usr/bin/virsh" ]; then VIRSH="/usr/bin/virsh"; else VIRSH=$(command -v virsh); fi
VM_NAME="Win11"

if [ -n "$VIRSH" ]; then
    echo "Wrapper: Checking VM state for '$VM_NAME'..."
    STATE=$($VIRSH domstate "$VM_NAME" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || echo "unknown")
    echo "Wrapper: Current state is '$STATE'"
    
    case "$STATE" in
        "running")
            echo "Wrapper: VM is already running."
            ;;
        "paused")
            echo "Wrapper: VM is paused, resuming..."
            $VIRSH resume "$VM_NAME" || echo "Wrapper: Warn - Failed to resume VM"
            ;;
        "pmsuspended")
            echo "Wrapper: VM is suspended (sleep). Waking up..."
            $VIRSH dompmwakeup "$VM_NAME" || $VIRSH start "$VM_NAME" || echo "Wrapper: Warn - Failed to wakeup VM"
            ;;
        "shutoff"|""|"unknown")
            echo "Wrapper: VM is off/unknown, starting..."
            $VIRSH start "$VM_NAME" || echo "Wrapper: Warn - Failed to start VM"
            sleep 1
            ;;
        *)
            echo "Wrapper: Unexpected state '$STATE', attempting start..."
            $VIRSH start "$VM_NAME" || echo "Wrapper: Warn - Failed to start VM"
            ;;
    esac
else
    echo "Wrapper: Warn - virsh not found, skipping wake."
fi

# --- WAIT FOR RDP PORT ---
IP="192.168.1.13"
PORT="3389"
echo "Wrapper: Waiting for port $IP:$PORT..."

MAX=180
count=0
while ! nc -z -w 1 "$IP" "$PORT"; do
    if (( count % 5 == 0 )); then
        echo "Wrapper: Port closed ($count/$MAX)..."
    fi
    sleep 1
    count=$((count+1))
    if [ "$count" -ge "$MAX" ]; then
        echo "Wrapper: Timeout waiting for VM to boot."
        exit 1
    fi
done

echo "Wrapper: Port Detected. Stabilizing (3s)..."
sleep 3

echo "Wrapper: Ready. Swapping FDs for Proxy..."

# --- HANDOVER TO SOCAT ---
exec 1>&3
exec 3>&-

echo "Wrapper: Executing socat..." >&2

SESSION_START=$(date +%s)
/usr/bin/socat STDIO "TCP:$IP:$PORT,retry=5"
SESSION_END=$(date +%s)
SESSION_DURATION=$((SESSION_END - SESSION_START))
MIN_SESSION=10

# --- CLEANUP (Suspend Decision) ---
echo "Wrapper: RDP Disconnected after ${SESSION_DURATION}s. Checking if should suspend..." >&2
sleep 2  # Let Windows shutdown start if that's what's happening

# Check 1: Other wrapper instances still running?
OTHER_WRAPPERS=$(pgrep -f "rdp-wake-wrapper" | grep -v $$ | wc -l)
if [ "$OTHER_WRAPPERS" -gt 0 ]; then
    echo "Wrapper: $OTHER_WRAPPERS other connection(s) active, not suspending." >&2
    exit 0
fi

# Check 2: Session too short? (failed connection)
if [ "$SESSION_DURATION" -lt "$MIN_SESSION" ]; then
    echo "Wrapper: Session too short (${SESSION_DURATION}s < ${MIN_SESSION}s), not suspending." >&2
    exit 0
fi

# Check 3: Is Windows still running? (port open AND guest agent responds)
PORT_OPEN="no"
nc -z -w 2 "$IP" "$PORT" && PORT_OPEN="yes"

AGENT_OK="no"
$VIRSH qemu-agent-command "$VM_NAME" '{"execute":"guest-ping"}' >/dev/null 2>&1 && AGENT_OK="yes"

echo "Wrapper: Port 3389 open: $PORT_OPEN, Guest agent responds: $AGENT_OK" >&2

if [ "$PORT_OPEN" = "yes" ] && [ "$AGENT_OK" = "yes" ]; then
    # Windows is running normally = User just closed RDP = Suspend
    echo "Wrapper: Windows running normally. Suspending VM..." >&2
    $VIRSH suspend "$VM_NAME" || echo "Wrapper: Warn - Failed to suspend VM"
else
    # Windows is shutting down or restarting = Don't suspend
    echo "Wrapper: Windows appears to be shutting down or restarting. Not suspending." >&2
fi

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
TimeoutStartSec=300
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
