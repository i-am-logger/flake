# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./persistence.nix
      ./secure-boot.nix  # Add this line
      ./yubikey.nix
      ./git.nix
      ./warp-terminal.nix
      # Add lanzaboote module
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

  # Filesystem configurations moved to disko.nix
  # Persistence configuration moved to persistence.nix


  # Bootloader.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  nix = {
    channel.enable = false;
    settings = {
      nix-path = ["nixpkgs=${pkgs.path}"];
      experimental-features = [ "nix-command" "flakes" ];
      
      # Build optimizations
      max-jobs = "auto";
      cores = 0;  # Use all cores
      sandbox = true;
      auto-optimise-store = true;
    };
  };

  networking.hostName = "yoga"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  # services.xserver.windowManager.notion.enable = true;

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


  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.logger = {
    isNormalUser = true;
    description = "Ido Samuelson";
    hashedPassword = "$6$xSY41iEBAU2B0KdA$Qk/yL0097FNXr2xEKVrjk1M6BUbQNgXYibBqlWwvhcV4h1JDE3bBmz61hynlu4w83ypyxgh66qowBjIkamsDC1";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      sbctl # for secure-boot
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

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
    vmtouch
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


  system.stateVersion = "25.05"; # Did you read the comment?
}
