#!/usr/bin/env bash

# Simple QEMU Windows Recovery with Proper Display
echo "=== QEMU Windows Recovery ==="
echo "This will boot your Ventoy USB in QEMU with a proper GUI window"
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "OVMF Code: $OVMF_CODE"
echo "OVMF Vars: $OVMF_VARS_TEMPLATE"
echo ""

# Create temp OVMF vars
TEMP_VARS="$HOME/ovmf_vars_recovery_gui.fd"
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "BCD Repair Commands (run these in Windows Command Prompt):"
echo "--------------------------------------------------------"
echo "diskpart"
echo "list disk"
echo "select disk 0"
echo "list partition"  
echo "select partition 1"
echo "assign letter=S"
echo "select partition 3"
echo "assign letter=C"
echo "exit"
echo ""
echo "bootrec /scanos"
echo "bootrec /rebuildbcd"
echo "bcdboot C:\\Windows /s S: /f UEFI"
echo ""
echo "dir S:\\EFI\\Microsoft\\Boot\\"
echo "--------------------------------------------------------"
echo ""

echo "Starting QEMU with GUI window..."
echo "1. A QEMU window will appear"
echo "2. Boot from Ventoy menu"
echo "3. Select Windows Recovery/PE"
echo "4. Go to Troubleshoot > Advanced > Command Prompt"
echo "5. Run the commands shown above"
echo ""

# Set display
export DISPLAY=${DISPLAY:-:0}

echo "Using display: $DISPLAY"
echo "Starting QEMU now..."

# QEMU command for recovery - USB boot first, then main disk available for repair
qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -smp 4 \
    -cpu host \
    -machine q35 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$TEMP_VARS" \
    -drive file="/dev/sda",format=raw,if=none,id=usb-drive \
    -device usb-storage,drive=usb-drive,bootindex=1 \
    -drive file="/dev/nvme0n1",format=raw,if=none,id=main-disk \
    -device nvme,drive=main-disk,serial=nvme-main,bootindex=2 \
    -device virtio-vga \
    -device virtio-mouse \
    -device virtio-keyboard \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -usb \
    -device usb-tablet \
    -boot order=a \
    -display sdl

echo ""
echo "Recovery session ended"

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "After running BCD repair commands, test with:"
echo "./qemu-windows.sh"
