#!/bin/bash

# Windows Boot Repair Script using QEMU
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

echo "Starting QEMU VM..."
echo "WARNING: This gives the VM raw access to your physical disk!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Run QEMU with physical device access
qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,accel=kvm \
    -cpu host \
    -smp 4 \
    -m 8G \
    -bios /nix/store/*/OVMF_CODE.fd \
    -drive if=pflash,format=raw,readonly=on,file=/nix/store/*/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=/tmp/ovmf_vars_$$.fd \
    -boot order=a \
    -drive file=/dev/sda,format=raw,if=none,id=usb-drive \
    -device usb-storage,drive=usb-drive,bootindex=1 \
    -drive file=/dev/nvme0n1,format=raw,if=none,id=main-disk \
    -device nvme,drive=main-disk,serial=nvme-main \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk,grab-on-hover=on \
    -usb \
    -device usb-tablet

echo "VM has been shut down."
