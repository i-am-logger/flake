#!/usr/bin/env bash

# Dual-Boot Verification Script
# This script checks if the dual-boot setup is properly configured

set -euo pipefail

echo "=== NixOS Windows Dual-Boot Verification ==="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    if [[ "$status" == "OK" ]]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [[ "$status" == "WARNING" ]]; then
        echo -e "${YELLOW}⚠${NC} $message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
}

check_partitions() {
    echo "=== Checking Partition Layout ==="
    
    if [[ -e "/dev/nvme0n1p1" ]]; then
        print_status "OK" "EFI partition found: /dev/nvme0n1p1"
    else
        print_status "ERROR" "EFI partition not found"
        return 1
    fi
    
    if [[ -e "/dev/nvme0n1p3" ]]; then
        print_status "OK" "Windows partition found: /dev/nvme0n1p3"
    else
        print_status "ERROR" "Windows partition not found"
        return 1
    fi
    
    # Check if Windows partition is NTFS
    local fs_type=$(sudo blkid -o value -s TYPE /dev/nvme0n1p3)
    if [[ "$fs_type" == "ntfs" ]]; then
        print_status "OK" "Windows partition is NTFS"
    else
        print_status "WARNING" "Windows partition is not NTFS (found: $fs_type)"
    fi
    
    echo ""
}

check_windows_efi() {
    echo "=== Checking Windows EFI Boot Files ==="
    
    if sudo test -f "/boot/EFI/Microsoft/Boot/bootmgfw.efi"; then
        print_status "OK" "Windows boot manager found: bootmgfw.efi"
    else
        print_status "ERROR" "Windows boot manager missing: /boot/EFI/Microsoft/Boot/bootmgfw.efi"
        return 1
    fi
    
    if sudo test -f "/boot/EFI/Microsoft/Boot/bootmgr.efi"; then
        print_status "OK" "Windows boot manager found: bootmgr.efi"
    else
        print_status "WARNING" "Secondary boot manager missing: bootmgr.efi"
    fi
    
    # Check file sizes (should be reasonable for boot files)
    local size=$(sudo stat -c%s "/boot/EFI/Microsoft/Boot/bootmgfw.efi")
    if [[ $size -gt 1000000 && $size -lt 5000000 ]]; then
        print_status "OK" "bootmgfw.efi size looks reasonable ($(($size / 1024)) KB)"
    else
        print_status "WARNING" "bootmgfw.efi size unusual: $(($size / 1024)) KB"
    fi
    
    echo ""
}

check_systemd_boot() {
    echo "=== Checking systemd-boot Configuration ==="
    
    if sudo test -f "/boot/loader/entries/windows.conf"; then
        print_status "OK" "Windows boot entry found"
        
        # Check the contents
        local entry_content=$(sudo cat /boot/loader/entries/windows.conf)
        if echo "$entry_content" | grep -q "title Windows"; then
            print_status "OK" "Windows entry has proper title"
        else
            print_status "ERROR" "Windows entry missing title"
        fi
        
        if echo "$entry_content" | grep -q "efi /EFI/Microsoft/Boot/bootmgfw.efi"; then
            print_status "OK" "Windows entry points to correct EFI file"
        else
            print_status "ERROR" "Windows entry has incorrect EFI path"
        fi
    else
        print_status "ERROR" "Windows boot entry not found: /boot/loader/entries/windows.conf"
        return 1
    fi
    
    # Check loader configuration
    if sudo test -f "/boot/loader/loader.conf"; then
        print_status "OK" "systemd-boot loader configuration found"
        
        local loader_content=$(sudo cat /boot/loader/loader.conf)
        if echo "$loader_content" | grep -q "timeout"; then
            local timeout=$(echo "$loader_content" | grep "timeout" | cut -d' ' -f2)
            if [[ $timeout -gt 0 ]]; then
                print_status "OK" "Boot timeout set to $timeout seconds"
            else
                print_status "WARNING" "Boot timeout is 0 - menu won't show"
            fi
        else
            print_status "WARNING" "No boot timeout configured"
        fi
    else
        print_status "ERROR" "systemd-boot loader configuration missing"
    fi
    
    echo ""
}

check_efi_boot_entries() {
    echo "=== Checking EFI Boot Entries ==="
    
    # Use efibootmgr to check boot entries
    if command -v efibootmgr >/dev/null 2>&1; then
        local boot_entries=$(efibootmgr -v 2>/dev/null || echo "Error reading boot entries")
        
        if echo "$boot_entries" | grep -q "Linux Boot Manager"; then
            print_status "OK" "Linux Boot Manager entry found"
        else
            print_status "WARNING" "Linux Boot Manager entry not found in firmware"
        fi
        
        if echo "$boot_entries" | grep -q "Windows"; then
            print_status "OK" "Windows entry found in firmware"
        else
            print_status "WARNING" "Windows entry not found in firmware (will use systemd-boot entry)"
        fi
    else
        print_status "WARNING" "efibootmgr not available - install with: nix-shell -p efibootmgr"
    fi
    
    echo ""
}

check_nixos_config() {
    echo "=== Checking NixOS Configuration ==="
    
    if grep -q "boot.loader.systemd-boot.enable = true" /etc/nixos/configuration.nix; then
        print_status "OK" "systemd-boot enabled in NixOS config"
    else
        print_status "ERROR" "systemd-boot not enabled in NixOS config"
    fi
    
    if grep -q "boot.loader.timeout" /etc/nixos/configuration.nix; then
        print_status "OK" "Boot timeout configured in NixOS"
    else
        print_status "WARNING" "Consider adding boot.loader.timeout to NixOS config"
    fi
    
    if grep -q "boot.supportedFilesystems.*ntfs" /etc/nixos/configuration.nix; then
        print_status "OK" "NTFS support enabled in NixOS config"
    else
        print_status "WARNING" "NTFS support not enabled - add boot.supportedFilesystems = [ \"ntfs\" ]"
    fi
    
    if grep -q "time.hardwareClockInLocalTime = true" /etc/nixos/configuration.nix; then
        print_status "OK" "Hardware clock set to local time (Windows compatibility)"
    else
        print_status "WARNING" "Hardware clock not set to local time - may cause time drift with Windows"
    fi
    
    echo ""
}

main() {
    echo "Verifying dual-boot setup..."
    echo ""
    
    local errors=0
    
    check_partitions || ((errors++))
    check_windows_efi || ((errors++))
    check_systemd_boot || ((errors++))
    check_efi_boot_entries
    check_nixos_config
    
    echo "=== Summary ==="
    if [[ $errors -eq 0 ]]; then
        print_status "OK" "Dual-boot setup appears to be working correctly!"
        echo ""
        echo "Next steps:"
        echo "1. Apply NixOS configuration changes (see nixos-dual-boot-patches.txt)"
        echo "2. Run: sudo nixos-rebuild switch"
        echo "3. Reboot and test both operating systems"
        echo ""
        echo "At boot, you should see:"
        echo "- NixOS (default)"
        echo "- Windows"
        echo ""
        echo "If Windows doesn't boot, run the repair script: ./fix-windows-boot.sh"
    else
        print_status "ERROR" "Found $errors critical issues that need to be fixed"
        echo ""
        echo "Run ./fix-windows-boot.sh to attempt automatic repair"
    fi
}

main "$@"
