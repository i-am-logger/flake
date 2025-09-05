#!/usr/bin/env bash

# QEMU Windows Boot Test with Logging and Monitoring
# This script boots Windows in QEMU to diagnose boot issues

set -euo pipefail

echo "=== QEMU Windows Boot Test with Monitoring ==="
echo "This will boot Windows in a VM to diagnose the boot failure"
echo ""

# Configuration
MAIN_DISK="/dev/nvme0n1"
WINDOWS_PARTITION="/dev/nvme0n1p3"
EFI_PARTITION="/dev/nvme0n1p1"
LOG_DIR="/tmp/qemu-windows-boot-$(date +%Y%m%d-%H%M%S)"
# Find OVMF firmware files dynamically
OVMF_CODE=$(find /nix/store -name "OVMF_CODE.fd" 2>/dev/null | head -1)
OVMF_VARS_TEMPLATE=$(find /nix/store -name "OVMF_VARS.fd" 2>/dev/null | head -1)

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Error: This script should not be run as root for safety reasons."
   echo "It will prompt for sudo when needed."
   exit 1
fi

# Create log directory
mkdir -p "$LOG_DIR"
echo "Logs will be saved to: $LOG_DIR"

# Function to check if devices exist
check_devices() {
    echo "Checking devices..."
    
    if [[ ! -e "$MAIN_DISK" ]]; then
        echo "ERROR: Main disk ($MAIN_DISK) not found!"
        exit 1
    fi
    
    if [[ ! -e "$WINDOWS_PARTITION" ]]; then
        echo "ERROR: Windows partition ($WINDOWS_PARTITION) not found!"
        exit 1
    fi
    
    if [[ ! -e "$EFI_PARTITION" ]]; then
        echo "ERROR: EFI partition ($EFI_PARTITION) not found!"
        exit 1
    fi
    
    echo "✓ All required partitions found"
}

# Function to check OVMF availability
check_ovmf() {
    echo "Checking OVMF UEFI firmware..."
    
    if [[ ! -f "$OVMF_CODE" ]]; then
        echo "ERROR: OVMF_CODE.fd not found at $OVMF_CODE"
        echo "Make sure QEMU with OVMF is properly installed in NixOS"
        exit 1
    fi
    
    if [[ ! -f "$OVMF_VARS_TEMPLATE" ]]; then
        echo "ERROR: OVMF_VARS.fd template not found at $OVMF_VARS_TEMPLATE"
        exit 1
    fi
    
    echo "✓ OVMF firmware found"
}

# Function to gather system information
gather_system_info() {
    echo "Gathering system information for diagnosis..."
    
    {
        echo "=== System Information ==="
        echo "Date: $(date)"
        echo "Kernel: $(uname -a)"
        echo ""
        
        echo "=== Disk Layout ==="
        lsblk -f
        echo ""
        
        echo "=== Partition Information ==="
        sudo fdisk -l "$MAIN_DISK"
        echo ""
        
        echo "=== EFI Boot Entries ==="
        efibootmgr -v || echo "efibootmgr failed"
        echo ""
        
        echo "=== Windows EFI Files ==="
        sudo find /boot/EFI -name "*.efi" | grep -i windows || echo "No Windows EFI files found"
        echo ""
        
        echo "=== systemd-boot Entries ==="
        sudo ls -la /boot/loader/entries/
        echo ""
        if sudo test -f "/boot/loader/entries/windows.conf"; then
            echo "Windows boot entry content:"
            sudo cat /boot/loader/entries/windows.conf
        fi
        echo ""
        
        echo "=== Windows Partition Check ==="
        sudo blkid "$WINDOWS_PARTITION"
        echo ""
        
    } > "$LOG_DIR/system-info.log" 2>&1
    
    echo "✓ System information saved to $LOG_DIR/system-info.log"
}

# Function to test Windows boot directly (without USB)
test_windows_direct_boot() {
    echo ""
    echo "=== Testing Direct Windows Boot ==="
    echo "This will attempt to boot Windows directly from the hard drive"
    echo ""
    
    # Create temporary OVMF vars file
    local temp_vars="$LOG_DIR/ovmf_vars_direct.fd"
    cp "$OVMF_VARS_TEMPLATE" "$temp_vars" 2>/dev/null || {
        echo "Creating new OVMF variables file..."
        dd if=/dev/zero of="$temp_vars" bs=1M count=4 2>/dev/null
    }
    
    echo "Starting QEMU VM for direct Windows boot test..."
    echo "Monitor output: VM will boot directly to Windows (or show error)"
    echo "Close VM window when done testing"
    echo ""
    
    # Run QEMU with detailed logging
    qemu-system-x86_64 \
        -enable-kvm \
        -machine q35,accel=kvm \
        -cpu host \
        -smp 4 \
        -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$temp_vars" \
        -drive file="$MAIN_DISK",format=raw,if=none,id=main-disk \
        -device nvme,drive=main-disk,serial=nvme-main \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
        -vga virtio \
        -display gtk,grab-on-hover=on \
        -usb \
        -device usb-tablet \
        -monitor stdio \
        -D "$LOG_DIR/qemu-direct-boot.log" \
        -d guest_errors,cpu_reset 2>&1 | tee "$LOG_DIR/qemu-console-direct.log"
    
    echo ""
    echo "Direct boot test completed."
}

# Function to test with Ventoy USB boot
test_windows_ventoy_boot() {
    echo ""
    echo "=== Testing Windows Boot via Ventoy Recovery ==="
    echo ""
    
    local ventoy_usb="/dev/sda"
    
    if [[ ! -e "$ventoy_usb" ]]; then
        echo "WARNING: Ventoy USB ($ventoy_usb) not found!"
        echo "Connect your Ventoy USB if you want to test recovery boot"
        read -p "Press Enter to skip Ventoy test, or connect USB and restart script..."
        return
    fi
    
    echo "Found Ventoy USB: $ventoy_usb"
    echo "This will boot from Ventoy for Windows recovery testing"
    echo ""
    
    # Create temporary OVMF vars file
    local temp_vars="$LOG_DIR/ovmf_vars_ventoy.fd"
    cp "$OVMF_VARS_TEMPLATE" "$temp_vars" 2>/dev/null || {
        echo "Creating new OVMF variables file..."
        dd if=/dev/zero of="$temp_vars" bs=1M count=4 2>/dev/null
    }
    
    read -p "Press Enter to start Ventoy recovery boot test..."
    
    # Run QEMU with Ventoy USB and main disk
    qemu-system-x86_64 \
        -enable-kvm \
        -machine q35,accel=kvm \
        -cpu host \
        -smp 4 \
        -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$temp_vars" \
        -boot order=a \
        -drive file="$ventoy_usb",format=raw,if=none,id=usb-drive \
        -device usb-storage,drive=usb-drive,bootindex=1 \
        -drive file="$MAIN_DISK",format=raw,if=none,id=main-disk \
        -device nvme,drive=main-disk,serial=nvme-main \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
        -vga virtio \
        -display gtk,grab-on-hover=on \
        -usb \
        -device usb-tablet \
        -monitor stdio \
        -D "$LOG_DIR/qemu-ventoy-boot.log" \
        -d guest_errors,cpu_reset 2>&1 | tee "$LOG_DIR/qemu-console-ventoy.log"
    
    echo ""
    echo "Ventoy recovery test completed."
}

# Function to analyze logs
analyze_logs() {
    echo ""
    echo "=== Analyzing Boot Logs ==="
    echo ""
    
    local analysis_file="$LOG_DIR/boot-analysis.txt"
    
    {
        echo "=== Boot Analysis Report ==="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== Log Files Created ==="
        ls -la "$LOG_DIR/"
        echo ""
        
        if [[ -f "$LOG_DIR/qemu-direct-boot.log" ]]; then
            echo "=== QEMU Direct Boot Errors ==="
            grep -i "error\|fail\|exception\|panic\|fatal" "$LOG_DIR/qemu-direct-boot.log" || echo "No obvious errors found"
            echo ""
        fi
        
        if [[ -f "$LOG_DIR/qemu-console-direct.log" ]]; then
            echo "=== Console Output Analysis ==="
            tail -50 "$LOG_DIR/qemu-console-direct.log"
            echo ""
        fi
        
        echo "=== Common Windows Boot Issues ==="
        echo "1. Missing or corrupted bootmgfw.efi"
        echo "2. BCD (Boot Configuration Database) corruption"
        echo "3. Windows partition filesystem issues"
        echo "4. UEFI firmware incompatibility"
        echo "5. Secure Boot conflicts"
        echo ""
        
        echo "=== Recommended Next Steps ==="
        echo "1. Check logs above for specific error messages"
        echo "2. Try Windows recovery tools from Ventoy USB"
        echo "3. Run Windows startup repair"
        echo "4. Use bootrec commands to rebuild boot configuration"
        echo ""
        
    } > "$analysis_file"
    
    echo "✓ Analysis saved to: $analysis_file"
    echo ""
    echo "=== Quick Log Summary ==="
    cat "$analysis_file"
}

# Main execution
main() {
    echo "Starting Windows boot diagnosis..."
    echo ""
    
    check_devices
    check_ovmf
    gather_system_info
    
    echo ""
    echo "=== Boot Test Options ==="
    echo "1. Test direct Windows boot (recommended first)"
    echo "2. Test Ventoy recovery boot"
    echo "3. Both tests"
    echo ""
    read -p "Select test option (1/2/3): " test_choice
    
    case $test_choice in
        1)
            test_windows_direct_boot
            ;;
        2)
            test_windows_ventoy_boot
            ;;
        3)
            test_windows_direct_boot
            echo ""
            read -p "Press Enter to continue with Ventoy test..."
            test_windows_ventoy_boot
            ;;
        *)
            echo "Invalid choice. Running direct boot test."
            test_windows_direct_boot
            ;;
    esac
    
    analyze_logs
    
    echo ""
    echo "=== Diagnosis Complete ==="
    echo "Logs and analysis saved in: $LOG_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Review the analysis file: cat $LOG_DIR/boot-analysis.txt"
    echo "2. Check QEMU logs for specific errors"
    echo "3. Use Windows recovery tools if needed"
    echo "4. Run bootrec commands to repair Windows boot"
}

# Run main function
main "$@"
