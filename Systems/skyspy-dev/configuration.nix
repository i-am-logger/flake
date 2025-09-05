# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./persistence.nix
    ../common/yubikey.nix
    ../common/warp-terminal.nix
    ../common/warp-terminal-preview.nix
    ../common/vscode.nix
  ];

  services.hardware.bolt.enable = true;

  # Bootloader - similar to current /etc/nixos setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 5;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Intel CPU specific modules
  boot.kernelModules = [ "kvm-intel" ];

  # Dual-boot support with Windows - based on /etc/nixos config
  time.hardwareClockInLocalTime = true;
  boot.supportedFilesystems = [ "ntfs" ];
  
  # Windows partition - read-only mount to ~/mnt/windows  
  fileSystems."/home/logger/mnt/windows" = {
    device = "/dev/disk/by-uuid/A03C41603C413318";
    fsType = "ntfs";
    options = [ "ro" "uid=1000" "gid=100" "dmask=022" "fmask=133" ];
    noCheck = true;
  };

  # Kernel and memory optimizations (from yoga)
  boot.kernel.sysctl = {
    # Network optimizations - BBR congestion control
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Security inode enhancements
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_queued_events" = 524288;

    # I/O and memory optimizations
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 3;
    "vm.dirty_ratio" = 8;
    "vm.transparent_hugepage" = "madvise";
    "vm.max_map_count" = 262144;
  };

  # Graphics and Nvidia configuration handled by common nvidia module

  networking.hostName = "skyspy-dev";
  networking.wireless.enable = false;
  hardware.bluetooth.enable = true; # Enable bluetooth

  # Security and audit (from yoga)
  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -F euid=0 -S execve"
    "-a exit,always -F arch=b32 -F euid=0 -S execve"
  ];

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=0
    Defaults !tty_tickets
    Defaults log_output
    Defaults log_input
    Defaults logfile=/var/log/sudo.log
  '';

  networking.networkmanager.enable = true;

  time.timeZone = "America/Denver";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true; # Disabled due to conflict with common/system.nix

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Audio configuration - ensure speaker is unmuted on boot (from /etc/nixos)
  systemd.services.fix-audio-speaker = {
    description = "Unmute Speaker on Boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset "Speaker" unmute || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  # Dual-boot support services (from /etc/nixos)
  services.udisks2.enable = true;         # Auto-mounting support
  services.timesyncd.enable = true;       # Network time sync (important for dual-boot)
  services.fstrim.enable = true;          # SSD optimization

  # Allow unfree packages for nvidia and other proprietary software
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    helix
    btop
    fastfetch
    mc
    git
    hyprland
    slack
    # Boot and partition management tools
    efibootmgr      # EFI boot entry management
    gparted         # Graphical partition editor
    ntfs3g          # NTFS filesystem support
    os-prober       # Detect other operating systems
    # File system tools
    dosfstools      # FAT/FAT32 tools
    parted          # Command line partitioning
    # Audio control tools
    pavucontrol     # PulseAudio volume control GUI
    pulseaudio      # PulseAudio utilities
    alsa-utils      # ALSA utilities (alsamixer, etc.)
    pipewire        # PipeWire utilities
  ];

  # Enable zram with 15% of RAM
  zramSwap = {
    enable = true;
    memoryPercent = 15;
  };

  # Service to load current system into RAM (adapted from yoga)
  systemd.services.nix-system-ram = {
    description = "Load current system closure into RAM";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    startAt = "boot";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "cache-system" ''
        # Cache current system
        ${pkgs.vmtouch}/bin/vmtouch -dl $(readlink -f /run/current-system)

        # Also cache current user profile
        ${pkgs.vmtouch}/bin/vmtouch -dl /nix/var/nix/profiles/per-user/logger/profile

        # Cache frequently used applications
        ${pkgs.vmtouch}/bin/vmtouch -dl /nix/store/*-firefox-*
        ${pkgs.vmtouch}/bin/vmtouch -dl /nix/store/*-warp-terminal-*

        # Report status
        echo "Current system closure size:"
        ${pkgs.nix}/bin/nix path-info -Sh /run/current-system
      '';
      ExecStop = pkgs.writeShellScript "uncache-system" ''
        ${pkgs.vmtouch}/bin/vmtouch -e $(readlink -f /run/current-system)
        ${pkgs.vmtouch}/bin/vmtouch -e /nix/var/nix/profiles/per-user/logger/profile
        ${pkgs.vmtouch}/bin/vmtouch -e /nix/store/*-firefox-*
        ${pkgs.vmtouch}/bin/vmtouch -e /nix/store/*-warp-terminal-*
      '';

      MemoryMax = "16G";
      Restart = "no";
      TimeoutStartSec = "5m";
    };
  };

  # system.stateVersion = "25.05"; # Commented due to conflict with common/system.nix
}
