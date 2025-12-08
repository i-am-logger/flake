#!/bin/bash

# Windows Boot Repair Script using QEMU v2
# This script boots Windows recovery tools from Ventoy USB and provides access to the physical disk

echo "=== Windows Boot Repair with QEMU ==="
echo "This will start a VM with:"
echo "- Ventoy USB as boot device (/dev/sda)"
echo "- Full physical disk access (/dev/nvme0n1)"
echo "- 8GB RAM, 4 CPU cores"
echo "- UEFI firmware (OVMF)"
echo ""

# Check if devices exist
if [ ! -e "/dev/sda" ]; then
    echo "ERROR: Ventoy USB (/dev/sda) not found!"
    echo "Please ensure your Ventoy USB is connected."
    exit 1
fi

if [ ! -e "/dev/nvme0n1" ]; then
    echo "ERROR: Main disk (/dev/nvme0n1) not found!"
    exit 1
fi

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

if [ -z "$OVMF_CODE" ] || [ -z "$OVMF_VARS" ]; then
    echo "ERROR: OVMF firmware files not found!"
    echo "Please ensure QEMU with UEFI support is installed."
    exit 1
fi

echo "Found OVMF firmware:"
echo "  Code: $OVMF_CODE"
echo "  Vars: $OVMF_VARS"
echo ""

# Create temporary OVMF vars file (writable)
TEMP_OVMF_VARS="/tmp/ovmf_vars_$$.fd"
cp "$OVMF_VARS" "$TEMP_OVMF_VARS"
chmod 644 "$TEMP_OVMF_VARS"

echo "Starting QEMU VM..."
echo "WARNING: This gives the VM raw access to your physical disk!"
echo "You can use Windows Recovery tools to fix the boot loader."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    rm -f "$TEMP_OVMF_VARS"
    exit 0
fi

echo "Starting VM... Press Ctrl+Alt+G to release mouse/keyboard from VM"
echo "To shut down cleanly, use the guest OS shutdown command"
echo ""

# Run QEMU with physical device access
qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,accel=kvm \
    -cpu host \
    -smp 4 \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TEMP_OVMF_VARS" \
    -boot order=a \
    -drive file=/dev/sda,format=raw,if=none,id=usb-drive,cache=none \
    -device usb-storage,drive=usb-drive,bootindex=1 \
    -drive file=/dev/nvme0n1,format=raw,if=none,id=main-disk,cache=none \
    -device nvme,drive=main-disk,serial=nvme-main \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk,grab-on-hover=on \
    -usb \
    -device usb-tablet \
    -device usb-kbd

echo ""
echo "VM has been shut down."
echo "Cleaning up temporary files..."
rm -f "$TEMP_OVMF_VARS"
echo "Done."
