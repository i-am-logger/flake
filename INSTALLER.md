# NixOS Unified Installer

A bootable ISO and installer script that handles both fresh installations and system updates for all configured systems.

## Building the Installer ISO

Build the custom installer ISO that includes all necessary tools:

```bash
cd /etc/nixos
nix build .#installer-iso
```

The ISO will be created at `./result/iso/nixos-installer-*.iso`

### Write to USB Drive

```bash
# Find your USB drive
lsblk

# Write the ISO (replace sdX with your drive)
sudo dd if=./result/iso/nixos-installer-*.iso of=/dev/sdX bs=4M status=progress
sync
```

## Booting the Installer ISO

1. Boot from the USB drive
2. You'll see a welcome banner with instructions
3. Connect to network (WiFi: use `nmtui`)
4. Clone your config and run the installer

## Systems

- **yoga** - Desktop system (AMD Ryzen, Gigabyte X870E)
- **skyspy-dev** - Laptop system (Lenovo Legion 16IRX8H, dual-boot with Windows)

## Usage

```bash
sudo ./install.sh [SYSTEM] install
```

The installer automatically detects whether to perform a fresh installation or update an existing system.

### Examples

```bash
# Install or update yoga
sudo ./install.sh yoga install

# Install or update skyspy-dev
sudo ./install.sh skyspy-dev install
```

## Behavior

### Fresh Installation

#### yoga
1. **Automatic partitioning** using disko (destroys all data on `/dev/nvme0n1`)
2. Creates optimized partition layout:
   - 2GB EFI boot partition
   - 128GB Nix store (btrfs with compression)
   - Remaining space for persistent data
   - tmpfs root for impermanence
3. Installs NixOS with full configuration
4. Configures bootloader (GRUB with Secure Boot via lanzaboote)

#### skyspy-dev
1. **Manual partitioning required** (dual-boot setup)
2. Prompts you to mount:
   - Root partition at `/mnt`
   - EFI partition at `/mnt/boot`
3. Preserves Windows partitions
4. Installs NixOS alongside Windows
5. Configures GRUB bootloader for dual-boot

### Update Existing System

For both systems:
1. Validates flake configuration
2. Builds new system configuration
3. Switches to new configuration
4. Updates bootloader automatically
5. Shows current generation info

## Fresh Installation Steps

### yoga

```bash
# Boot from NixOS installation media
# Ensure you have network connectivity

# Clone the configuration
git clone git@github.com:i-am-logger/nixos-config.git /etc/nixos
cd /etc/nixos

# Run installer (will auto-partition and install)
sudo ./install.sh yoga install
```

### skyspy-dev

```bash
# Boot from NixOS installation media
# Ensure you have network connectivity

# Partition disk manually (preserve Windows)
# Example:
mount /dev/nvme0n1p5 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Clone the configuration
git clone git@github.com:i-am-logger/nixos-config.git /mnt/etc/nixos
cd /mnt/etc/nixos

# Run installer
sudo ./install.sh skyspy-dev install
```

## Update Existing System

Simply run on an already installed system:

```bash
cd /etc/nixos
sudo ./install.sh yoga install
# or
sudo ./install.sh skyspy-dev install
```

## Features

- **Auto-detection**: Automatically determines if performing fresh install or update
- **Safety checks**: Confirms destructive operations before proceeding
- **Bootloader repair**: Updates bootloader during system updates
- **Dual-boot aware**: Handles Windows dual-boot configuration for skyspy-dev
- **Color-coded output**: Clear visual feedback during installation
- **Error handling**: Validates partitions, mounts, and configuration before proceeding

## Requirements

- Root access (run with `sudo`)
- NixOS installation media (for fresh installs)
- Network connectivity
- For skyspy-dev: Pre-partitioned disk with Windows preserved

## Troubleshooting

### Fresh install fails on yoga
- Verify `/dev/nvme0n1` is the correct disk
- Ensure no partitions are mounted
- Check disko configuration in `Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7/disko.nix`

### Fresh install fails on skyspy-dev
- Verify partitions are correctly mounted at `/mnt` and `/mnt/boot`
- Check that Windows partitions are not affected
- Use `lsblk` to verify partition layout

### Update fails
- Ensure flake configuration is valid: `nix flake check`
- Check for syntax errors in configuration files
- Verify `/boot` partition is mounted

### Bootloader issues
- For yoga: Check lanzaboote configuration for Secure Boot
- For skyspy-dev: Verify GRUB is configured for dual-boot
- Run `nixos-rebuild boot` and reboot if needed

## Integration with rebuild-system

The installer complements your existing `rebuild-system` command:
- `rebuild-system` - Quick updates on current system
- `./install.sh [system] install` - Full install/update with bootloader repair
