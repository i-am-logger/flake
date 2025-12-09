#!/usr/bin/env bash

# Simple Windows Recovery Boot
# Boots directly to Windows recovery using Ventoy USB

echo "=== Simple Windows Recovery Boot ==="
echo ""
echo "This will boot your Ventoy USB in QEMU so you can:"
echo "1. Select Windows recovery tools"
echo "2. Open Command Prompt"
echo "3. Run BCD repair commands"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

# Create temp OVMF vars
TEMP_VARS="$HOME/ovmf_vars_recovery.fd"
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "=== BCD Repair Commands (for when you get to Windows Command Prompt) ==="
echo ""
echo "1. Set up drive letters:"
echo "   diskpart"
echo "   list disk"
echo "   select disk 0"
echo "   list partition"
echo "   select partition 1    # EFI partition (~1GB)"
echo "   assign letter=S"
echo "   select partition 3    # Windows partition (~2TB)"
echo "   assign letter=C"
echo "   exit"
echo ""
echo "2. Rebuild BCD:"
echo "   bootrec /scanos"
echo "   bootrec /rebuildbcd"
echo "   bcdboot C:\\Windows /s S: /f UEFI"
echo ""
echo "3. Verify:"
echo "   dir S:\\EFI\\Microsoft\\Boot\\"
echo "   # Should show BCD file"
echo ""

read -p "Press Enter to start Windows Recovery in QEMU..."

echo ""
echo "Starting QEMU with Ventoy USB..."
echo "Use the QEMU window to:"
echo "1. Boot from Ventoy"
echo "2. Select Windows Recovery"
echo "3. Go to Troubleshoot > Advanced > Command Prompt"
echo "4. Run the commands shown above"
echo ""

# Start QEMU with GUI - this should definitely show a window
qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,accel=kvm \
    -cpu host \
    -smp 4 \
    -m 8G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TEMP_VARS" \
    -boot order=a \
    -drive file="/dev/sda",format=raw,if=none,id=usb-drive \
    -device usb-storage,drive=usb-drive,bootindex=1 \
    -drive file="/dev/nvme0n1",format=raw,if=none,id=main-disk \
    -device nvme,drive=main-disk,serial=nvme-main \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -vga virtio \
    -display gtk \
    -usb \
    -device usb-tablet

echo ""
echo "QEMU recovery session ended."
echo "Did you successfully rebuild the BCD?"

# Cleanup
rm -f "$TEMP_VARS"
