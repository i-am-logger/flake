#!/usr/bin/env bash

# Windows Boot Repair Script for NixOS Dual-Boot Setup
# This script repairs Windows boot files and sets up dual-boot with systemd-boot

set -euo pipefail

echo "=== Windows Boot Repair and Dual-Boot Setup ==="
echo "This script will:"
echo "1. Check current boot configuration"
echo "2. Repair Windows EFI boot files using QEMU (if needed)"
echo "3. Create Windows boot entry for systemd-boot"
echo "4. Update NixOS configuration for optimal dual-boot support"
echo ""

# Configuration
MAIN_DISK="/dev/nvme0n1"
WINDOWS_PARTITION="/dev/nvme0n1p3"
EFI_PARTITION="/dev/nvme0n1p1"
VENTOY_USB="/dev/sda"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Error: This script should not be run as root for safety reasons."
   echo "It will prompt for sudo when needed."
   exit 1
fi

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

# Function to check for Windows EFI files
check_windows_efi() {
    echo "Checking for Windows EFI boot files..."
    
    if sudo test -d "/boot/EFI/Microsoft" && sudo test -f "/boot/EFI/Microsoft/Boot/bootmgfw.efi"; then
        echo "✓ Windows EFI boot files found"
        return 0
    else
        echo "⚠ Windows EFI boot files missing"
        return 1
    fi
}

# Function to repair Windows boot using QEMU
repair_windows_boot() {
    echo ""
    echo "=== Repairing Windows Boot Files ==="
    echo ""
    
    if [[ ! -e "$VENTOY_USB" ]]; then
        echo "ERROR: Ventoy USB ($VENTOY_USB) not found!"
        echo "Please connect your Ventoy USB drive with Windows recovery tools."
        exit 1
    fi
    
    echo "Starting QEMU VM for Windows boot repair..."
    echo "Instructions for Windows Recovery:"
    echo "1. Boot from Windows recovery media"
    echo "2. Open Command Prompt (Troubleshoot > Advanced > Command Prompt)"
    echo "3. Run these commands:"
    echo "   bootrec /fixmbr"
    echo "   bootrec /fixboot"
    echo "   bootrec /scanos"
    echo "   bootrec /rebuildbcd"
    echo "   bcdboot C:\\Windows /s S: /f UEFI"
    echo "4. Exit and shutdown the VM"
    echo ""
    
    read -p "Press Enter to start the repair VM, or Ctrl+C to skip..."
    
    # Create temporary OVMF vars file
    TEMP_VARS="/tmp/ovmf_vars_repair_$$.fd"
    cp "/run/current-system/firmware/ovmf/OVMF_VARS.fd" "$TEMP_VARS" 2>/dev/null || {
        echo "Creating temporary OVMF variables file..."
        dd if=/dev/zero of="$TEMP_VARS" bs=1M count=4 2>/dev/null
    }
    
    # Run QEMU with physical device access for repair
    qemu-system-x86_64 \
        -enable-kvm \
        -machine q35,accel=kvm \
        -cpu host \
        -smp 4 \
        -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="/run/current-system/firmware/ovmf/OVMF_CODE.fd" \
        -drive if=pflash,format=raw,file="$TEMP_VARS" \
        -boot order=a \
        -drive file="$VENTOY_USB",format=raw,if=none,id=usb-drive \
        -device usb-storage,drive=usb-drive,bootindex=1 \
        -drive file="$MAIN_DISK",format=raw,if=none,id=main-disk \
        -device nvme,drive=main-disk,serial=nvme-main \
        -netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
        -vga virtio \
        -display gtk,grab-on-hover=on \
        -usb \
        -device usb-tablet
    
    # Cleanup
    rm -f "$TEMP_VARS"
    
    echo "VM repair session completed."
}

# Function to create Windows systemd-boot entry
create_windows_boot_entry() {
    echo ""
    echo "=== Creating Windows Boot Entry ==="
    echo ""
    
    # Check if Windows EFI files exist now
    if ! check_windows_efi; then
        echo "Warning: Windows EFI files still not found. The boot entry may not work."
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ "$continue_anyway" != "y" ]]; then
            echo "Skipping Windows boot entry creation."
            return
        fi
    fi
    
    # Create Windows boot entry for systemd-boot
    WINDOWS_ENTRY="/boot/loader/entries/windows.conf"
    
    echo "Creating Windows boot entry: $WINDOWS_ENTRY"
    
    sudo tee "$WINDOWS_ENTRY" > /dev/null << 'EOF'
title Windows
efi /EFI/Microsoft/Boot/bootmgfw.efi
EOF
    
    echo "✓ Windows boot entry created"
    
    # Update boot loader configuration
    echo "Updating systemd-boot configuration..."
    
    sudo tee "/boot/loader/loader.conf" > /dev/null << 'EOF'
default nixos-generation-*.conf
timeout 5
console-mode keep
editor no
EOF
    
    echo "✓ Boot loader configuration updated"
}

# Function to update NixOS configuration for better dual-boot support
update_nixos_config() {
    echo ""
    echo "=== Updating NixOS Configuration ==="
    echo ""
    
    # Backup current configuration
    sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
    echo "✓ Configuration backed up to /etc/nixos/configuration.nix.backup"
    
    # Create updated configuration with dual-boot optimizations
    cat << 'EOF' > /tmp/dual_boot_additions.nix
  # Dual-boot optimizations for Windows compatibility
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 5;
  
  # Windows time synchronization fix (prevent time drift between OSes)
  time.hardwareClockInLocalTime = true;
  
  # NTFS support for accessing Windows partitions
  boot.supportedFilesystems = [ "ntfs" ];
  
  # Windows partition auto-discovery and mounting
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/A03C41603C413318";
    fsType = "ntfs-3g"; 
    options = [ "rw" "uid=1000" "gid=100" "dmask=022" "fmask=133" ];
  };
EOF
    
    echo "Dual-boot configuration additions created."
    echo "You should manually integrate these settings into your /etc/nixos/configuration.nix"
    echo ""
    cat /tmp/dual_boot_additions.nix
    echo ""
    
    read -p "Would you like to view the complete updated configuration example? (y/N): " show_example
    if [[ "$show_example" == "y" ]]; then
        echo ""
        echo "=== Example Updated Configuration ==="
        echo "Add these settings to your /etc/nixos/configuration.nix:"
        cat /tmp/dual_boot_additions.nix
    fi
}

# Function to install Windows boot repair tools in NixOS
install_boot_tools() {
    echo ""
    echo "=== Installing Boot Repair Tools ==="
    echo ""
    
    echo "Adding useful boot tools to your NixOS configuration..."
    echo "Consider adding these packages to your environment.systemPackages:"
    echo "  efibootmgr    # EFI boot manager"
    echo "  ntfs3g        # NTFS filesystem support"
    echo "  gparted       # Partition management"
    echo "  os-prober     # OS detection utility"
}

# Main execution
main() {
    echo "Starting Windows boot repair and dual-boot setup..."
    echo ""
    
    check_devices
    
    if check_windows_efi; then
        echo "Windows EFI files found. Skipping repair."
        repair_needed=false
    else
        echo "Windows EFI files missing. Repair needed."
        repair_needed=true
        
        read -p "Do you want to run Windows boot repair using QEMU? (y/N): " run_repair
        if [[ "$run_repair" == "y" ]]; then
            repair_windows_boot
        else
            echo "Skipping Windows boot repair. Note: Boot entry may not work without proper EFI files."
        fi
    fi
    
    read -p "Create Windows boot entry for systemd-boot? (y/N): " create_entry
    if [[ "$create_entry" == "y" ]]; then
        create_windows_boot_entry
    fi
    
    read -p "Show dual-boot NixOS configuration recommendations? (y/N): " show_config
    if [[ "$show_config" == "y" ]]; then
        update_nixos_config
    fi
    
    install_boot_tools
    
    echo ""
    echo "=== Summary ==="
    echo "✓ Boot repair script completed"
    echo ""
    echo "Next steps:"
    echo "1. If you modified NixOS configuration, run: sudo nixos-rebuild switch"
    echo "2. Reboot and test both NixOS and Windows boot options"
    echo "3. If Windows still doesn't boot, run the repair process again"
    echo ""
    echo "Boot entries should be available at startup with a 5-second timeout."
}

# Run main function
main "$@"
