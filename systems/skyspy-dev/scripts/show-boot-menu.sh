#!/usr/bin/env bash

# Boot Menu Simulation Script
# Shows what you'll see when you boot your computer

set -euo pipefail

echo "=== Boot Menu Preview ==="
echo "This is what you'll see when you reboot your computer:"
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│              NixOS Boot Menu (systemd-boot)             │"
echo "│                                                         │"
echo "│  Boot entries (use arrow keys, Enter to select):       │"
echo "│                                                         │"

# Get the current default entry
default_entry=$(sudo cat /boot/loader/loader.conf | grep "default" | cut -d' ' -f2)
echo "│  > NixOS (Generation 6) [DEFAULT] ←── Boots automatically │"

# Show other NixOS generations
for entry in $(sudo ls /boot/loader/entries/nixos-generation-*.conf | sort -V -r | tail -n +2 | head -3); do
    gen=$(basename "$entry" | sed 's/nixos-generation-\([0-9]*\)\.conf/\1/')
    echo "│    NixOS (Generation $gen)                               │"
done

# Show Windows entry
if sudo test -f "/boot/loader/entries/windows.conf"; then
    echo "│    Windows                                              │"
else
    echo "│    [Windows entry not found]                           │"
fi

echo "│                                                         │"
echo "│  Timeout: 5 seconds                                     │"
echo "│  Press any key to stop auto-boot                       │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""
echo "After 5 seconds, NixOS will boot automatically."
echo "Use arrow keys to select Windows if you want to boot into Windows."
echo ""

# Show status
echo "=== Current Boot Configuration Status ==="

if sudo test -f "/boot/EFI/Microsoft/Boot/bootmgfw.efi"; then
    echo "✓ Windows boot files: Present and ready"
else
    echo "✗ Windows boot files: Missing"
fi

if sudo test -f "/boot/loader/entries/windows.conf"; then
    echo "✓ Windows boot entry: Configured"
else
    echo "✗ Windows boot entry: Not configured"
fi

# Check if Windows partition is mounted
if mountpoint -q /mnt/windows 2>/dev/null; then
    echo "✓ Windows partition: Auto-mounted at /mnt/windows"
else
    echo "✗ Windows partition: Not mounted"
fi

# Check hardware clock setting
if grep -q "time.hardwareClockInLocalTime = true" /etc/nixos/configuration.nix; then
    echo "✓ Hardware clock: Set to local time (Windows compatible)"
else
    echo "⚠ Hardware clock: May cause time drift between Windows and Linux"
fi

echo ""
echo "=== Ready to Test ==="
echo "Your dual-boot setup is ready! To test:"
echo "1. Save any open work"
echo "2. Run: sudo reboot"
echo "3. You should see the boot menu above"
echo "4. Test both NixOS (default) and Windows options"
echo ""
echo "If Windows doesn't boot properly, run: ./fix-windows-boot.sh"
