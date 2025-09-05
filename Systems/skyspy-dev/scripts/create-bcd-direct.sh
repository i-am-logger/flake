#!/usr/bin/env bash

# Direct BCD Creation from Linux
# Creates a basic Windows BCD file without needing Windows recovery

echo "=== Direct BCD Creation from Linux ==="
echo ""
echo "This will attempt to create a basic BCD file directly from Linux."
echo "This is often faster than using Windows recovery tools."
echo ""

# Check if we have the necessary tools
if ! command -v mtools >/dev/null 2>&1; then
    echo "Installing mtools for FAT filesystem access..."
    # We'll need mtools to work with the EFI FAT partition
    echo "Please install mtools first: nix-shell -p mtools"
    exit 1
fi

# Mount the EFI partition if not already mounted
EFI_MOUNT="/mnt/efi"
if ! mountpoint -q "$EFI_MOUNT" 2>/dev/null; then
    echo "Mounting EFI partition..."
    sudo mkdir -p "$EFI_MOUNT"
    sudo mount /dev/nvme0n1p1 "$EFI_MOUNT"
fi

echo "Current EFI partition contents:"
sudo ls -la "$EFI_MOUNT/EFI/"
echo ""

# Check if Windows boot files exist
if sudo ls "$EFI_MOUNT/EFI/Microsoft/Boot/" >/dev/null 2>&1; then
    echo "✓ Windows boot directory exists"
    sudo ls -la "$EFI_MOUNT/EFI/Microsoft/Boot/"
    
    if sudo test -f "$EFI_MOUNT/EFI/Microsoft/Boot/BCD"; then
        echo "⚠ BCD file already exists. Backing it up..."
        sudo cp "$EFI_MOUNT/EFI/Microsoft/Boot/BCD" "$EFI_MOUNT/EFI/Microsoft/Boot/BCD.backup"
    fi
else
    echo "✗ Windows boot directory missing"
    echo "Creating Windows boot directory structure..."
    sudo mkdir -p "$EFI_MOUNT/EFI/Microsoft/Boot"
fi

echo ""
echo "=== Creating Basic BCD File ==="
echo ""

# Create a basic BCD template
# This is a simplified approach - we'll create a minimal BCD that points to the Windows loader

cat << 'EOF' > /tmp/bcd_template.txt
# Basic BCD Template for Windows UEFI Boot
# This creates minimal boot configuration

Windows Boot Manager
identifier              {bootmgr}  
device                  partition=S:
description             Windows Boot Manager
locale                  en-us
inherit                 {globalsettings}
default                 {default}
resumeobject            {5bb8c3c0-5f1f-11ea-8d71-806e6f6e6963}
displayorder            {default}
toolsdisplayorder       {memdiag}
timeout                 30

Windows Boot Loader
identifier              {default}
device                  partition=C:
path                    \Windows\system32\winload.efi
description             Windows
locale                  en-us
inherit                 {bootloadersettings}
recoverysequence        {5bb8c3c2-5f1f-11ea-8d71-806e6f6e6963}
recoveryenabled         Yes
allowedinmemorysettings 0x15000075
osdevice                partition=C:
systemroot              \Windows
resumeobject            {5bb8c3c0-5f1f-11ea-8d71-806e6f6e6963}
nx                      OptIn
bootmenupolicy          Standard

EOF

echo "BCD template created. However, BCD files are binary and require special tools."
echo ""
echo "=== Alternative Approach: Use Windows Boot Files Directly ==="
echo ""

# Let's try to use the Windows boot files we copied earlier
echo "Checking Windows boot files on EFI partition..."

if sudo test -f "$EFI_MOUNT/EFI/Microsoft/Boot/bootmgfw.efi"; then
    echo "✓ bootmgfw.efi found"
else
    echo "✗ bootmgfw.efi missing"
    echo "Copying Windows boot files..."
    
    # Copy from Windows installation
    if sudo test -f "/mnt/windows/Windows/Boot/EFI/bootmgfw.efi"; then
        sudo cp "/mnt/windows/Windows/Boot/EFI/bootmgfw.efi" "$EFI_MOUNT/EFI/Microsoft/Boot/"
        sudo cp "/mnt/windows/Windows/Boot/EFI/bootmgr.efi" "$EFI_MOUNT/EFI/Microsoft/Boot/"
        echo "✓ Boot files copied"
    else
        echo "✗ Cannot find Windows boot files"
    fi
fi

echo ""
echo "=== Summary ==="
echo "Direct BCD creation from Linux is complex because BCD files are"
echo "Microsoft-specific binary registry files that require Windows tools."
echo ""
echo "Recommended approach:"
echo "1. Use Windows recovery tools: ./console-windows-recovery.sh"
echo "2. Or try the manual BCD recreation process"
echo ""
echo "The Windows recovery approach is more reliable for creating a proper BCD."

# Cleanup
rm -f /tmp/bcd_template.txt

echo ""
read -p "Would you like to try the Windows recovery approach now? (y/N): " try_recovery

if [[ "$try_recovery" == "y" ]]; then
    echo "Starting Windows recovery..."
    ./console-windows-recovery.sh
fi
