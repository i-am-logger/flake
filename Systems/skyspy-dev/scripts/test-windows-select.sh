#!/usr/bin/env bash

# Test Windows Boot Selection in QEMU
# This will boot directly to Windows option to see the error

set -euo pipefail

echo "=== Test Windows Boot Selection ==="
echo "This will attempt to boot the Windows entry directly"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "Using OVMF firmware:"
echo "  CODE: $OVMF_CODE"
echo "  VARS: $OVMF_VARS_TEMPLATE"
echo ""

# Create temporary OVMF vars and log files
TEMP_VARS="$HOME/ovmf_vars_windows_test.fd"
LOG_FILE="$HOME/qemu-windows-select-$(date +%Y%m%d-%H%M%S).log"

# Remove any existing temp file and create new one
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "Starting Windows test in QEMU..."
echo "This will try to boot Windows directly to see what error occurs."
echo "Use Ctrl+A then X to exit QEMU if it hangs."
echo "Log will be saved to: $LOG_FILE"
echo ""
echo "========== WINDOWS BOOT TEST =========="

# We'll try to boot with the windows entry directly
# First let's run QEMU and let the user manually select Windows

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,accel=kvm \
    -cpu host \
    -smp 4 \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TEMP_VARS" \
    -drive file="/dev/nvme0n1",format=raw,if=none,id=main-disk \
    -device nvme,drive=main-disk,serial=nvme-main \
    -nographic \
    -serial stdio \
    -monitor none \
    -boot menu=on,splash-time=10000 \
    -D "$LOG_FILE" \
    -d guest_errors,unimp,cpu_reset 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "========== BOOT TEST ENDED =========="
echo ""

# Analyze the output
echo "=== Boot Analysis ==="
echo ""
echo "Log file: $LOG_FILE"
echo ""

if [[ -f "$LOG_FILE" ]]; then
    echo "=== Searching for Windows boot errors ==="
    
    if grep -qi "windows\|bootmgr\|winload\|bcd\|boot.*fail" "$LOG_FILE"; then
        echo "Found Windows boot related messages:"
        grep -i "windows\|bootmgr\|winload\|bcd\|boot.*fail" "$LOG_FILE" || true
        echo ""
    fi
    
    if grep -qi "error\|exception\|panic\|fatal\|fail" "$LOG_FILE"; then
        echo "Found error messages:"
        grep -i "error\|exception\|panic\|fatal\|fail" "$LOG_FILE" | tail -10 || true
        echo ""
    fi
    
    echo "=== Last 30 lines of output ==="
    tail -30 "$LOG_FILE"
    
fi

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "=== Analysis ==="
echo "Did you see an error when trying to select Windows?"
echo "Common errors might be:"
echo "- 'The Boot Configuration Data file is missing'"
echo "- 'winload.efi missing or corrupt'"  
echo "- 'No operating system found'"
echo "- Just a blank screen or hanging"
echo ""
echo "If Windows failed to boot, run './repair-windows-bcd.sh' to fix the BCD."
