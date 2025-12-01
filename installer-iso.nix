{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ISO identity
  isoImage.volumeID = "NIXOS_INSTALLER";

  # Enable flakes and experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Include essential tools for installation
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh

    # Disk management
    gptfdisk
    parted

    # File systems
    btrfs-progs
    e2fsprogs
    dosfstools
    ntfs3g

    # Network tools
    curl
    wget

    # Text editors
    vim
    nano

    # System tools
    util-linux
    pciutils
    usbutils

    # Convenience
    tmux
    htop
    tree
  ];

  # Enable SSH for remote installation
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Automatic network configuration
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  # Include the installer script in the ISO
  environment.etc."nixos-installer/install.sh" = {
    source = ./install.sh;
    mode = "0755";
  };

  # Create a helper script that's in PATH
  environment.etc."nixos-installer/README.md" = {
    text = ''
      NixOS System Installer
      ======================

      This ISO can install or update the following systems:
      - yoga: Desktop system (AMD Ryzen, Gigabyte X870E)
      - skyspy-dev: Laptop system (Lenovo Legion 16IRX8H, dual-boot)

      Quick Start
      -----------

      1. Ensure network connectivity:
         sudo systemctl start NetworkManager
         nmtui  # For WiFi configuration

      2. Clone the configuration repository:
         git clone git@github.com:i-am-logger/nixos-config.git /tmp/nixos-config
         # or with HTTPS:
         git clone https://github.com/i-am-logger/nixos-config.git /tmp/nixos-config

      3. Run the installer:
         cd /tmp/nixos-config
         sudo ./install.sh yoga install
         # or
         sudo ./install.sh skyspy-dev install

      Fresh Installation vs Update
      ----------------------------

      The installer automatically detects:
      - If running from live ISO -> Fresh installation
      - If running on existing NixOS -> Update/rebuild

      For Updates on Existing Systems
      --------------------------------

      If you booted this ISO to repair/update an existing installation:

      1. Mount your existing system:
         mount /dev/nvme0n1p3 /mnt  # Adjust partition as needed
         mount /dev/nvme0n1p1 /mnt/boot

      2. Enter the system:
         nixos-enter

      3. Navigate to your config and rebuild:
         cd /etc/nixos
         nixos-rebuild switch --flake .#yoga
         # or
         nixos-rebuild switch --flake .#skyspy-dev

      SSH Access
      ----------

      Root has no password by default. Set one to enable SSH:
         passwd

      Then connect from another machine:
         ssh root@<ip-address>

      Documentation
      ------------

      Full installer documentation is in the repository at:
      /tmp/nixos-config/INSTALLER.md (after cloning)
    '';
    mode = "0644";
  };

  # Set a welcome message
  programs.bash.shellInit = ''
    cat << 'EOF'

    ╔═══════════════════════════════════════════════════════════╗
    ║           NixOS System Installer Live ISO                ║
    ║                                                           ║
    ║  Supports: yoga, skyspy-dev                               ║
    ║  Mode: Fresh Install or System Update/Repair             ║
    ╚═══════════════════════════════════════════════════════════╝

    Quick start:
      1. Check network: nmtui (for WiFi)
      2. Read instructions: cat /etc/nixos-installer/README.md
      3. Clone repo and run installer

    For SSH access: passwd (root has no password by default)

    EOF
  '';

  # Allow empty root password for live ISO convenience
  users.users.root.password = "";

  # Compression for smaller ISO
  isoImage.squashfsCompression = "zstd -Xcompression-level 15";
}
