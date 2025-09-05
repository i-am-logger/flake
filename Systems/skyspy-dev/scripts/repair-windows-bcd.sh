#!/usr/bin/env bash

# Windows BCD (Boot Configuration Database) Repair Script
# Uses Ventoy USB and QEMU to rebuild Windows boot configuration

set -euo pipefail

echo "=== Windows BCD Repair Script ==="
echo "This script will help you rebuild the Windows Boot Configuration Database"
echo "which appears to be missing or corrupted."
echo ""

# Configuration
MAIN_DISK="/dev/nvme0n1"
VENTOY_USB="/dev/sda"

# Find OVMF files
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

echo "=== Diagnosis ==="
echo "The issue appears to be a missing Boot Configuration Database (BCD)."
echo "This is essential for Windows UEFI boot process."
echo ""
echo "Missing components:"
echo "- BCD file (should be on EFI partition or Windows Boot directory)"
echo "- Proper boot entries pointing to Windows loader"
echo ""

check_requirements() {
    echo "=== Checking Requirements ==="
    
    if [[ ! -e "$VENTOY_USB" ]]; then
        echo "ERROR: Ventoy USB not found at $VENTOY_USB"
        echo "Please connect your Ventoy USB drive with Windows recovery tools."
        echo "Available devices:"
        lsblk | grep -E "(sda|sdb|sdc)"
        exit 1
    fi
    
    echo "✓ Ventoy USB found: $VENTOY_USB"
    echo "✓ Main disk found: $MAIN_DISK"
    echo "✓ OVMF firmware available"
    echo ""
}

show_repair_instructions() {
    echo "=== Windows BCD Repair Instructions ==="
    echo ""
    echo "I will boot Windows Recovery Environment via QEMU."
    echo "Follow these steps in the Windows recovery console:"
    echo ""
    echo "1. Boot from Ventoy and select Windows Recovery"
    echo "2. Choose 'Troubleshoot' > 'Advanced Options' > 'Command Prompt'"
    echo "3. Run these commands in order:"
    echo ""
    echo "   # List disks and identify your Windows disk"
    echo "   diskpart"
    echo "   list disk"
    echo "   select disk 0    (assuming your main drive is disk 0)"
    echo "   list partition"
    echo "   # Note: Look for the EFI partition (usually ~100-500MB, FAT32)"
    echo "   # and the Windows partition (large NTFS partition)"
    echo "   exit"
    echo ""
    echo "   # Assign drive letters (adjust numbers based on your partitions)"
    echo "   diskpart"
    echo "   select disk 0"
    echo "   select partition 1    # EFI partition"
    echo "   assign letter=S"
    echo "   select partition 3    # Windows partition (your main Windows install)"
    echo "   assign letter=C"
    echo "   exit"
    echo ""
    echo "   # Rebuild BCD and boot files"
    echo "   bootrec /fixmbr"
    echo "   bootrec /fixboot"
    echo "   bootrec /scanos"
    echo "   bootrec /rebuildbcd"
    echo ""
    echo "   # Rebuild boot files on EFI partition"
    echo "   bcdboot C:\\Windows /s S: /f UEFI"
    echo ""
    echo "   # Verify BCD was created"
    echo "   dir S:\\EFI\\Microsoft\\Boot\\"
    echo "   # You should see BCD file and other boot files"
    echo ""
    echo "4. Exit and restart the VM to test"
    echo "5. If successful, reboot your actual machine"
    echo ""
    read -p "Press Enter when you're ready to start the recovery environment..."
}

start_recovery_vm() {
    echo ""
    echo "=== Starting Windows Recovery VM ==="
    echo ""
    
    echo "Choose display mode:"
    echo "1. GUI mode (opens window) - easier for Windows recovery"
    echo "2. Console mode (text only) - for debugging"
    read -p "Select mode (1/2): " display_mode
    
    # Create temporary OVMF vars
    TEMP_VARS="/tmp/ovmf_vars_repair.fd"
    cp "$OVMF_VARS_TEMPLATE" "$TEMP_VARS"
    
    echo "Launching QEMU with Ventoy and your main disk..."
    echo "This gives you access to Windows Recovery tools with your actual disk."
    echo ""
    
    # Base QEMU command
    local qemu_cmd="qemu-system-x86_64 \
        -enable-kvm \
        -machine q35,accel=kvm \
        -cpu host \
        -smp 4 \
        -m 8G \
        -drive if=pflash,format=raw,readonly=on,file=\"$OVMF_CODE\" \
        -drive if=pflash,format=raw,file=\"$TEMP_VARS\" \
        -boot order=a \
        -drive file=\"$VENTOY_USB\",format=raw,if=none,id=usb-drive \
        -device usb-storage,drive=usb-drive,bootindex=1 \
        -drive file=\"$MAIN_DISK\",format=raw,if=none,id=main-disk \
        -device nvme,drive=main-disk,serial=nvme-main \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0"
    
    # Add display options based on choice
    if [[ "$display_mode" == "2" ]]; then
        echo "Starting in console mode (use Ctrl+A then X to exit)..."
        eval "$qemu_cmd \
            -nographic \
            -serial stdio \
            -monitor none"
    else
        echo "Starting in GUI mode..."
        eval "$qemu_cmd \
            -vga virtio \
            -display gtk,grab-on-hover=on \
            -usb \
            -device usb-tablet"
    fi
    
    echo ""
    echo "Recovery session completed."
    
    # Cleanup
    rm -f "$TEMP_VARS"
}

test_windows_boot() {
    echo ""
    echo "=== Testing Windows Boot After Repair ==="
    echo ""
    
    read -p "Do you want to test if Windows boots now? (y/N): " test_boot
    
    if [[ "$test_boot" == "y" ]]; then
        echo "Testing Windows boot directly..."
        
        TEMP_VARS="/tmp/ovmf_vars_test_after_repair.fd"
        cp "$OVMF_VARS_TEMPLATE" "$TEMP_VARS"
        
        qemu-system-x86_64 \
            -enable-kvm \
            -machine q35,accel=kvm \
            -cpu host \
            -smp 4 \
            -m 8G \
            -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
            -drive if=pflash,format=raw,file="$TEMP_VARS" \
            -drive file="$MAIN_DISK",format=raw,if=none,id=main-disk \
            -device nvme,drive=main-disk,serial=nvme-main \
            -vga virtio \
            -display gtk,grab-on-hover=on
        
        rm -f "$TEMP_VARS"
        
        echo ""
        echo "Did Windows boot successfully? If yes, you can now reboot your"
        echo "actual machine and Windows should appear in the systemd-boot menu."
    fi
}

main() {
    echo "Starting BCD repair process..."
    echo ""
    
    check_requirements
    show_repair_instructions
    start_recovery_vm
    test_windows_boot
    
    echo ""
    echo "=== BCD Repair Complete ==="
    echo ""
    echo "If the repair was successful:"
    echo "1. Windows should now boot from the systemd-boot menu"
    echo "2. The BCD file should be recreated on the EFI partition"
    echo "3. Windows boot entries should be properly configured"
    echo ""
    echo "If Windows still doesn't boot:"
    echo "1. The Windows installation may be corrupted"
    echo "2. Try Windows Startup Repair from recovery tools"
    echo "3. Consider reinstalling Windows (keeping data on partition)"
    echo ""
    echo "Next: Reboot your machine and test the dual-boot menu!"
}

main "$@"
