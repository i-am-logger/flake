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
    ./secure-boot.nix # Add this line
    ./yubikey.nix
    # ./git.nix
    ./warp-terminal.nix
    ./warp-terminal-preview.nix
    # Add lanzaboote module
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  services.hardware.bolt.enable = true;

  # Filesystem configurations moved to disko.nix
  # Persistence configuration moved to persistence.nix

  # Bootloader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [
    "amdgpu.dc_feature_mask=0xffffffff" # Enable all DC features including DSC
    "amdgpu.deep_color=1" # HDR
    "amdgpu.dc=1" # Display Core
    "amdgpu.dpm=1"
    "amdgpu.dp_mst=1" # Enable DisplayPort Multi-Stream Transport
  ];

  # Kernel and memory optimizations
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

  hardware.graphics = {
    enable = true;
    # driSupport = true;
    enable32Bit = true; # If you need 32-bit application support
    extraPackages = with pkgs; [
      amdvlk
      # rocm-opencl-icd
      # rocm-opencl-runtime
      libvdpau-va-gl
      vaapiVdpau
      libva-utils
    ];
    # For 32-bit application support (e.g., Steam)
    extraPackages32 = with pkgs.pkgsi686Linux; [
      amdvlk
    ];
  };

  networking.hostName = "yoga";
  networking.wireless.enable = false;
  hardware.bluetooth.enable = false;

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
  # services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or pkg.name) [
      "slack"
      "warp-terminal"
      "warp-terminal-preview"
      "1password"
      "1password-cli"
    ];
  # Define a user account. Don't forget to set a password with 'passwd'.

  # Install firefox.
  # programs.firefox.enable = true;
  # programs.hyprland.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    helix
    btop
    fastfetch
    mc
    git
    # vmtouch
    hyprland
    slack
  ];

  # Enable zram with 15% of RAM
  zramSwap = {
    enable = true;
    memoryPercent = 15;
  };

  # Service to load current system into RAM
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

  system.stateVersion = "25.11"; # Did you read the comment?
}
