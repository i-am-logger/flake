#!/usr/bin/env bash

# Simple Windows Boot Test via QEMU
echo "=== Simple Windows Boot Test ==="
echo "This will boot Windows directly in QEMU to see the error"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "Using OVMF firmware:"
echo "  CODE: $OVMF_CODE"
echo "  VARS: $OVMF_VARS_TEMPLATE"
echo ""

# Create temporary OVMF vars
TEMP_VARS="/tmp/ovmf_vars_test.fd"
cp "$OVMF_VARS_TEMPLATE" "$TEMP_VARS"

echo "Starting Windows in QEMU..."
echo "Watch for any error messages in the VM window"
echo "Close the VM window when you've seen the error"
echo ""

# Run QEMU with minimal setup
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
    -vga virtio \
    -display gtk,grab-on-hover=on

echo ""
echo "QEMU test completed."
echo "What did you see in the VM? Please describe the error."

# Cleanup
rm -f "$TEMP_VARS"
