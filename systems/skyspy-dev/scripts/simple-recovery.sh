#!/usr/bin/env bash

# Simple Console-Only Windows Recovery
echo "=== Simple Windows Recovery (Console Only) ==="
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

# Create temp OVMF vars
TEMP_VARS="$HOME/ovmf_vars_simple.fd"
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "BCD Repair Commands (copy these for Windows Command Prompt):"
echo ""
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
echo ""

read -p "Press Enter to start Windows Recovery in console mode..."

echo ""
echo "Starting QEMU console mode (use Ctrl+A then X to exit)..."
echo "========== RECOVERY CONSOLE =========="

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
    -nographic \
    -serial stdio \
    -monitor none

echo ""
echo "Recovery session ended."

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "Test Windows boot with: ./test-windows-select.sh"
