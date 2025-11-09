# Installer ISO Quick Start

## Build the ISO

```bash
./build-installer.sh
```

Or manually:
```bash
nix build .#installer-iso
```

## Write to USB

```bash
# Find your USB device
lsblk

# Write ISO to USB (replace sdX with your device)
sudo dd if=./result/iso/nixos-installer-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Using the Installer ISO

### Boot the ISO

1. Insert USB and boot from it
2. You'll see a welcome banner
3. Default root password is `nixos` (for SSH access)

### Fresh Installation

#### For yoga (automatic partitioning):

```bash
# Connect to network
nmtui  # for WiFi

# Clone configuration
git clone https://github.com/i-am-logger/nixos-config.git /tmp/nixos-config
cd /tmp/nixos-config

# Run installer
sudo ./install.sh yoga install
```

#### For skyspy-dev (manual partitioning, dual-boot):

```bash
# Connect to network
nmtui

# Partition disk (preserve Windows)
# Example:
mount /dev/nvme0n1p5 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Clone configuration
git clone https://github.com/i-am-logger/nixos-config.git /mnt/etc/nixos
cd /mnt/etc/nixos

# Run installer
sudo ./install.sh skyspy-dev install
```

### Repair/Update Existing System

If you need to repair or update an already installed system:

```bash
# Mount existing system
mount /dev/nvme0n1pX /mnt  # Your root partition
mount /dev/nvme0n1p1 /mnt/boot  # EFI partition

# Enter the system
nixos-enter

# Inside the system, rebuild
cd /etc/nixos
git pull  # Update configuration if needed
nixos-rebuild switch --flake .#yoga
# or
nixos-rebuild switch --flake .#skyspy-dev
```

## Remote Installation via SSH

```bash
# On the installer ISO, set root password
passwd

# Find IP address
ip addr

# From another machine
ssh root@<ip-address>

# Then follow installation steps above
```

## What's Included in the ISO

- **Essential tools**: git, vim, tmux, parted, btrfs-progs
- **Network**: NetworkManager for WiFi/ethernet
- **Your installer script**: Automatically install/update both systems
- **SSH server**: For remote installation
- **Flakes enabled**: Ready to build from your flake configuration

## Troubleshooting

### WiFi not working
```bash
sudo systemctl start NetworkManager
nmtui
```

### Can't access GitHub
Use HTTPS instead of SSH:
```bash
git clone https://github.com/i-am-logger/nixos-config.git /tmp/nixos-config
```

### Need to check disk layout
```bash
lsblk
fdisk -l
```

### ISO won't boot
- Verify UEFI boot mode in BIOS
- Try different USB port
- Rebuild ISO if corrupted
