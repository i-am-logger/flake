#!/usr/bin/env bash

# Console Windows Boot Test via QEMU
# Runs QEMU in console mode to capture boot output directly

set -euo pipefail

echo "=== Console Windows Boot Test ==="
echo "This will boot Windows in QEMU and show all output in the console"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "Using OVMF firmware:"
echo "  CODE: $OVMF_CODE"
echo "  VARS: $OVMF_VARS_TEMPLATE"
echo ""

# Create temporary OVMF vars and log files in home directory
TEMP_VARS="$HOME/ovmf_vars_console_test.fd"
LOG_FILE="$HOME/qemu-console-boot-$(date +%Y%m%d-%H%M%S).log"

# Remove any existing temp file and create new one
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"  # Make it writable

echo "Starting Windows in QEMU (console mode)..."
echo "Boot output will appear below. Press Ctrl+A then X to exit QEMU."
echo "Log will be saved to: $LOG_FILE"
echo ""
echo "========== QEMU BOOT OUTPUT =========="

# Run QEMU in console mode with serial output
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
    -boot menu=on,splash-time=5000 \
    -D "$LOG_FILE" \
    -d guest_errors,unimp,cpu_reset 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "========== QEMU SESSION ENDED =========="
echo ""

# Analyze the output
echo "=== Boot Analysis ==="
echo ""
echo "Log file: $LOG_FILE"
echo ""

if [[ -f "$LOG_FILE" ]]; then
    echo "=== Last 30 lines of boot log ==="
    tail -30 "$LOG_FILE"
    echo ""
    
    echo "=== Searching for error patterns ==="
    
    if grep -qi "boot.*fail\|no.*boot\|bootmgr\|winload\|bcd" "$LOG_FILE"; then
        echo "Found boot-related errors:"
        grep -i "boot.*fail\|no.*boot\|bootmgr\|winload\|bcd" "$LOG_FILE" || true
    else
        echo "No obvious boot errors found in patterns"
    fi
    
    if grep -qi "error\|exception\|panic\|fatal" "$LOG_FILE"; then
        echo ""
        echo "Other errors found:"
        grep -i "error\|exception\|panic\|fatal" "$LOG_FILE" || true
    fi
    
    echo ""
    echo "=== OVMF/UEFI Messages ==="
    grep -i "ovmf\|uefi\|efi.*boot\|shell>" "$LOG_FILE" | tail -10 || echo "No OVMF messages found"
    
fi

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "=== Diagnosis ==="
echo "Based on the output above, the most likely issues are:"
echo "1. Missing BCD (Boot Configuration Database) - most probable"
echo "2. Corrupted Windows boot loader"
echo "3. UEFI boot configuration pointing to wrong location"
echo ""
echo "Next step: Run './repair-windows-bcd.sh' to rebuild the boot configuration"
