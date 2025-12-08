#!/usr/bin/env bash

# Console Windows Recovery Boot
# Boots Windows recovery in console mode with VNC access

echo "=== Console Windows Recovery Boot ==="
echo ""
echo "This will boot your Ventoy USB in QEMU console mode."
echo "You can access it via VNC or serial console."
echo ""

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

# Create temp OVMF vars
TEMP_VARS="$HOME/ovmf_vars_recovery_console.fd"
rm -f "$TEMP_VARS"
dd if="$OVMF_VARS_TEMPLATE" of="$TEMP_VARS" bs=1M 2>/dev/null
chmod 644 "$TEMP_VARS"

echo "=== BCD Repair Commands ==="
echo "(Copy these commands for use in Windows Command Prompt)"
echo ""
echo "1. Set up drive letters:"
echo "   diskpart"
echo "   list disk"
echo "   select disk 0"
echo "   list partition"
echo "   select partition 1"
echo "   assign letter=S"
echo "   select partition 3"
echo "   assign letter=C"
echo "   exit"
echo ""
echo "2. Rebuild BCD:"
echo "   bootrec /scanos"
echo "   bootrec /rebuildbcd"
echo "   bcdboot C:\\Windows /s S: /f UEFI"
echo ""
echo "3. Verify BCD was created:"
echo "   dir S:\\EFI\\Microsoft\\Boot\\"
echo ""

echo "=== Starting QEMU Recovery Environment ==="
echo ""
echo "Choose access method:"
echo "1. VNC (connect with VNC viewer to localhost:5900)"
echo "2. Console mode (text-based, limited graphics support)"
echo "3. Try GUI mode anyway"
echo ""
read -p "Select option (1/2/3): " access_mode

case $access_mode in
    1)
        echo ""
        echo "Starting QEMU with VNC server..."
        echo "Connect your VNC client to: localhost:5900"
        echo "Use Ctrl+C in this terminal to stop QEMU"
        echo ""
        
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
            -vga std \
            -vnc :0 \
            -usb \
            -device usb-tablet
        ;;
    2)
        echo ""
        echo "Starting QEMU in console mode..."
        echo "Use Ctrl+A then X to exit QEMU"
        echo ""
        echo "========== QEMU CONSOLE OUTPUT =========="
        
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
            -nographic \
            -serial stdio \
            -monitor none
        ;;
    3)
        echo ""
        echo "Attempting GUI mode..."
        echo "If no window appears, try VNC or console mode instead"
        echo ""
        
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
            -display gtk,grab-on-hover=on \
            -usb \
            -device usb-tablet
        ;;
    *)
        echo "Invalid option selected"
        ;;
esac

echo ""
echo "QEMU session ended."

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "After running BCD repair commands, test Windows boot with:"
echo "./test-windows-select.sh"
