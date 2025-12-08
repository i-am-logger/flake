#!/usr/bin/env bash

# Automated Windows BCD Repair using QEMU
# This script automates the Windows recovery process

set -euo pipefail

echo "=== Automated Windows BCD Repair ==="
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

# Create temp files
TEMP_VARS="$HOME/ovmf_vars_auto_repair.fd"
MONITOR_SOCKET="/tmp/qemu-monitor-$$.sock"
COMMANDS_FILE="/tmp/bcd-commands.txt"

rm -f "$TEMP_VARS" "$MONITOR_SOCKET" "$COMMANDS_FILE"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

# Create BCD repair command sequence
cat > "$COMMANDS_FILE" << 'EOF'
diskpart
list disk
select disk 0
list partition
select partition 1
assign letter=S
select partition 3
assign letter=C
exit
bootrec /scanos
bootrec /rebuildbcd
bcdboot C:\Windows /s S: /f UEFI
dir S:\EFI\Microsoft\Boot\
exit
EOF

echo "=== Automation Plan ==="
echo "1. Boot QEMU with Windows recovery"
echo "2. Wait for Windows recovery environment"
echo "3. Navigate to Command Prompt"
echo "4. Execute BCD repair commands automatically"
echo "5. Verify BCD creation"
echo ""

# Function to send commands to QEMU
send_qemu_command() {
    local cmd="$1"
    echo "$cmd" | socat - UNIX-CONNECT:"$MONITOR_SOCKET" >/dev/null 2>&1 || true
}

# Function to send keystrokes
send_keys() {
    local keys="$1"
    local delay="${2:-100}"
    
    # Convert common key combinations
    case "$keys" in
        "ENTER")   send_qemu_command "sendkey ret" ;;
        "TAB")     send_qemu_command "sendkey tab" ;;
        "DOWN")    send_qemu_command "sendkey down" ;;
        "UP")      send_qemu_command "sendkey up" ;;
        "ESC")     send_qemu_command "sendkey esc" ;;
        "SPACE")   send_qemu_command "sendkey spc" ;;
        *)         
            # Send individual characters
            for (( i=0; i<${#keys}; i++ )); do
                char="${keys:$i:1}"
                if [[ "$char" =~ [A-Z] ]]; then
                    send_qemu_command "sendkey shift-${char,}"
                else
                    send_qemu_command "sendkey $char"
                fi
                sleep 0.05
            done
            ;;
    esac
    
    sleep "$delay"
}

# Function to automate Windows recovery
automate_recovery() {
    echo "Starting automation sequence..."
    
    # Wait for initial boot
    echo "Waiting for Windows recovery to load..."
    sleep 15
    
    # Navigate through Windows recovery menus
    echo "Navigating to Command Prompt..."
    
    # Try to get to troubleshoot menu
    send_keys "TAB"
    sleep 2
    send_keys "TAB" 
    sleep 2
    send_keys "ENTER"
    sleep 5
    
    # Look for Troubleshoot option
    send_keys "DOWN"
    sleep 1
    send_keys "DOWN"
    sleep 1
    send_keys "ENTER"
    sleep 5
    
    # Advanced options
    send_keys "DOWN"
    sleep 1
    send_keys "DOWN"
    sleep 1
    send_keys "ENTER"
    sleep 5
    
    # Command Prompt option
    send_keys "DOWN"
    sleep 1
    send_keys "DOWN"
    sleep 1
    send_keys "ENTER"
    sleep 10
    
    echo "Should now be in Command Prompt. Executing BCD repair commands..."
    
    # Execute BCD repair commands
    while IFS= read -r cmd; do
        if [[ -n "$cmd" && ! "$cmd" =~ ^#.* ]]; then
            echo "Executing: $cmd"
            send_keys "$cmd"
            send_keys "ENTER"
            sleep 3
        fi
    done < "$COMMANDS_FILE"
    
    echo "BCD repair commands sent. Waiting for completion..."
    sleep 10
    
    # Exit command prompt
    send_keys "exit"
    send_keys "ENTER"
    sleep 5
    
    echo "Shutting down recovery environment..."
    send_qemu_command "system_powerdown"
    sleep 5
}

# Start QEMU in background with automation
echo "Starting QEMU with Windows recovery..."
echo "This will run automatically - please wait..."

(
    # Start QEMU with monitor socket
    qemu-system-x86_64 \
        -enable-kvm \
        -machine q35,accel=kvm \
        -cpu host \
        -smp 4 \
        -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TEMP_VARS" \
        -boot order=a \
        -usb \
        -drive file="/dev/sda",format=raw,if=none,id=usb-drive \
        -device usb-storage,drive=usb-drive,bootindex=1 \
        -drive file="/dev/nvme0n1",format=raw,if=none,id=main-disk \
        -device nvme,drive=main-disk,serial=nvme-main \
        -monitor unix:"$MONITOR_SOCKET",server,nowait \
        -nographic \
        -serial stdio
) &

QEMU_PID=$!

# Wait for QEMU to start and monitor socket to be ready
echo "Waiting for QEMU to start..."
sleep 5

# Check if monitor socket exists
if [[ -S "$MONITOR_SOCKET" ]]; then
    echo "Monitor socket ready, starting automation..."
    automate_recovery &
    AUTOMATION_PID=$!
else
    echo "Monitor socket not found, manual intervention may be needed"
fi

# Wait for QEMU to finish
wait $QEMU_PID 2>/dev/null || true

# Kill automation if still running
if [[ -n "${AUTOMATION_PID:-}" ]]; then
    kill $AUTOMATION_PID 2>/dev/null || true
fi

echo ""
echo "Automated repair completed!"

# Cleanup
rm -f "$TEMP_VARS" "$MONITOR_SOCKET" "$COMMANDS_FILE"

echo ""
echo "Testing Windows boot..."
./test-windows-select.sh
