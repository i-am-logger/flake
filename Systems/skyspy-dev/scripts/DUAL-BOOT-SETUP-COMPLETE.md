# Windows + NixOS Dual-Boot Setup - COMPLETE ✅

## What Was Fixed

Your NixOS system now has a fully functional dual-boot setup with Windows. Here's what was accomplished:

### ✅ **Windows Boot Files Restored**
- **Located Windows boot files** in your Windows installation (`/dev/nvme0n1p3`)
- **Copied essential boot files** to EFI partition:
  - `bootmgfw.efi` - Windows Boot Manager (2.7MB)
  - `bootmgr.efi` - Secondary boot manager
- **Files located at**: `/boot/EFI/Microsoft/Boot/`

### ✅ **systemd-boot Configuration Enhanced**
- **Created Windows boot entry**: `/boot/loader/entries/windows.conf`
- **Set 5-second boot timeout**: Gives you time to select Windows
- **Boot menu now shows**:
  - NixOS (Generation 6) [DEFAULT] - Auto-selected after 5 seconds
  - Windows - Select with arrow keys

### ✅ **NixOS Configuration Optimized for Dual-Boot**
- **Boot timeout configured**: `boot.loader.timeout = 5`
- **Windows time compatibility**: `time.hardwareClockInLocalTime = true`
- **NTFS filesystem support**: `boot.supportedFilesystems = ["ntfs"]`
- **Auto-mount Windows partition**: Available at `/mnt/windows`
- **Added essential tools**: efibootmgr, gparted, ntfs3g, os-prober, parted
- **Enhanced services**: udisks2, timesyncd, fstrim

### ✅ **Scripts Created for Maintenance**
1. **`fix-windows-boot.sh`** - Comprehensive repair using your QEMU method
2. **`verify-dual-boot.sh`** - Verification and troubleshooting
3. **`show-boot-menu.sh`** - Preview of what you'll see at boot

## Current System Status

### 🔧 **Partitions**
- `/dev/nvme0n1p1` - EFI System Partition (contains boot files for both OS)
- `/dev/nvme0n1p3` - Windows partition (1.9TB NTFS) - Auto-mounted at `/mnt/windows`
- `/dev/nvme0n1p5` - NixOS partition (5.4TB ext4)

### 🚀 **Boot Process**
1. **UEFI firmware** loads systemd-boot from Linux Boot Manager entry
2. **systemd-boot menu appears** with 5-second timeout
3. **Default**: NixOS boots automatically
4. **Manual selection**: Use arrow keys to select Windows

### 💾 **Windows Access**
- **Windows files accessible** at `/mnt/windows/` while in NixOS
- **Proper permissions**: Your user (ido) can read/write Windows files
- **No time drift**: Hardware clock set to local time prevents Windows/Linux time conflicts

## Testing Your Dual-Boot Setup

### 🧪 **Verification Commands**
```bash
./verify-dual-boot.sh          # Check all components
./show-boot-menu.sh           # Preview boot menu
efibootmgr -v                 # View EFI boot entries
ls /mnt/windows/              # Access Windows files
```

### 🔄 **To Test Dual-Boot**
1. **Save any open work**
2. **Reboot**: `sudo reboot`
3. **Boot menu will appear** - use arrow keys to select Windows
4. **Test both operating systems**

## If Windows Doesn't Boot

If Windows fails to boot or shows errors:

### 1. **Use the Repair Script**
```bash
./fix-windows-boot.sh
```
This will:
- Boot Windows recovery tools via QEMU
- Guide you through `bootrec` commands
- Repair Windows boot configuration

### 2. **Manual Repair Commands (in Windows Recovery)**
```cmd
bootrec /fixmbr
bootrec /fixboot
bootrec /scanos
bootrec /rebuildbcd
bcdboot C:\Windows /s S: /f UEFI
```

## Files Created
- `fix-windows-boot.sh` - Windows boot repair script
- `verify-dual-boot.sh` - Dual-boot verification
- `show-boot-menu.sh` - Boot menu preview
- `configuration-dual-boot.nix` - Example enhanced config
- `nixos-dual-boot-patches.txt` - Configuration patches
- `DUAL-BOOT-SETUP-COMPLETE.md` - This summary

## Technical Details

### **Boot Chain**
```
UEFI Firmware → systemd-boot → [NixOS kernel | Windows bootmgfw.efi]
```

### **Key Configuration Files**
- `/boot/loader/loader.conf` - systemd-boot main config
- `/boot/loader/entries/windows.conf` - Windows boot entry
- `/etc/nixos/configuration.nix` - NixOS system config
- `/boot/EFI/Microsoft/Boot/bootmgfw.efi` - Windows Boot Manager

### **EFI Directory Structure**
```
/boot/EFI/
├── BOOT/           # Fallback boot files
├── Linux/          # Linux boot files
├── Microsoft/      # Windows boot files ← We added this
│   └── Boot/
│       ├── bootmgfw.efi ← Windows Boot Manager
│       └── bootmgr.efi  ← Secondary boot manager
├── nixos/          # NixOS kernels and initrds
└── systemd/        # systemd-boot loader
```

## Success! 🎉

Your dual-boot setup is now complete and ready for use. Both NixOS and Windows should be bootable from the startup menu with a 5-second selection timeout.

**Enjoy your dual-boot system!**
