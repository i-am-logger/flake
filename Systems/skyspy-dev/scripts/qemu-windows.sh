#!/usr/bin/env bash

# Simple QEMU Windows Boot with Proper Display
echo "=== QEMU Windows Boot ==="
echo "This will boot Windows in QEMU with a proper GUI window"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "OVMF Code: $OVMF_CODE"
echo "OVMF Vars: $OVMF_VARS_TEMPLATE"
echo ""

# Create temp OVMF vars
TEMP_VARS="$HOME/ovmf_vars_gui.fd"
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "Starting QEMU with GUI window..."
echo "A QEMU window should appear showing Windows boot"
echo ""

# Try different display methods
export DISPLAY=${DISPLAY:-:0}

echo "Using display: $DISPLAY"
echo "Starting QEMU now..."

# Use the simplest possible QEMU command that should definitely show a window
qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -smp 4 \
    -cpu host \
    -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TEMP_VARS" \
    -drive file="/dev/nvme0n1",format=raw,if=virtio,id=disk0 \
    -device virtio-vga \
    -device virtio-mouse \
    -device virtio-keyboard \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -boot order=c \
    -display sdl

echo ""
echo "QEMU session ended"

# Cleanup
rm -f "$TEMP_VARS"
