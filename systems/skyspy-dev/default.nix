{ mynixos, ... }:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = {
    # System configuration
    system = {
      enable = true;
      hostname = "skyspy-dev";
      # kernel defaults to mynixos system module (linuxPackages_latest)
      # Overridden in extraModules below to use linuxPackages_6_12 for NVIDIA compatibility
    };

    # Hardware configuration (laptop automatically sets cpu/gpu/bluetooth/audio)
    hardware = {
      laptops.lenovo.legion-16irx8h.enable = true;

      # Peripherals
      peripherals.elgato.streamdeck.enable = true;
    };

    # Boot configuration
    boot = {
      dualBoot.enable = true; # Windows dual-boot support
    };

    # Filesystem configuration
    filesystem = {
      type = "nixos";
      config = ./filesystem.nix;
    };

    # Theme configuration
    themes = {
      type = "stylix";
      config = ../../themes/stylix.nix;
    };

    # Environment configuration
    environment = {
      enable = true;
      xdg.enable = true;

      motd = {
        enable = true;
        content = builtins.readFile ../motd.txt;
      };
    };

    # Security configuration
    security = {
      enable = true;
      secureBoot.enable = false; # skyspy-dev doesn't have secure boot yet
      yubikey.enable = true;
      auditRules.enable = false;
    };

    # Infrastructure configuration
    # - docker: Auto-enabled by user dev feature
    # - k3s: Disabled on laptop
    # - github-runner: Disabled
    # Note: direnv and vscode are now per-user apps (my.users.<name>.apps.dev)
    infra = {
      k3s.enable = false; # Disable k3s on laptop

      github-runner = {
        enable = false;
        enableGpu = true;
        repositories = [
          "flake"
          "loial"
          "logger"
          "pds"
        ];
      };
    };

    # Video/Streaming: System-level video infrastructure
    # - Virtual camera (v4l2loopback) - auto-enabled when user has graphical.streaming.enable = true
    # Note: OBS is per-user in my.users.<name>.graphical.streaming
    # Note: StreamDeck moved to my.hardware.peripherals.elgato.streamdeck
    video = {
      # Temporarily disabled due to v4l2loopback kernel 6.18 incompatibility
      # virtual.enable = false;  # Auto-enabled by user streaming flag
    };

    # AI configuration
    ai = {
      enable = false; # Ollama disabled on skyspy-dev
      # mcpServers is now configured per-user in my.users.<name>.ai.mcpServers
    };

    # Performance configuration
    performance = {
      enable = true;
      zramPercent = 15;
      vmtouchCache = true;
    };

    # Storage configuration (impermanence + disko)
    storage.impermanence = {
      enable = true;
      useDedicatedPartition = false; # skyspy-dev uses tmpfiles, not dedicated partition
      persistUserData = true;
      cloneFlakeRepo = "git@github.com:i-am-logger/flake.git";
      symlinkFlakeToHome = true; # Automatically create ~/.flake symlink for all users (auto-detected from my.users)
      # Custom directories (applied to all users)
      extraUserDirectories = [ "GitHub" ]; # skyspy-dev uses GitHub instead of Code
    };

    # Personal user data (for mynixos features)
    # User definitions are imported from /etc/nixos/users/
    users =
      let
        baseUsers = import ../../users;
      in
      baseUsers
      // {
        # System-specific configuration for skyspy-dev
        logger = baseUsers.logger // {
          # Windows mount
          mounts = [
            {
              mountPoint = "/home/logger/mnt/windows";
              device = "A03C41603C413318"; # Will be prefixed with /dev/disk/by-uuid/
              fsType = "ntfs";
              options = [
                "ro"
                "uid=1000"
                "gid=100"
                "dmask=022"
                "fmask=133"
              ];
              noCheck = true;
            }
          ];

        };
      };

    # Hardware specs (cpu, gpu, bluetooth, audio) are defined in the laptop module
  };

  # System-specific configuration (personal, not opinionated)
  extraModules = [
    # WORKAROUND: Use kernel 6.17 due to NVIDIA open driver incompatibility with 6.18
    # The open driver fails to compile with kernel 6.18 (get_dev_pagemap API change)
    # Can be removed once NVIDIA driver is updated to support kernel 6.18
    (
      { pkgs, lib, ... }:
      {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

        # Use NVIDIA open source kernel modules (required for driver >= 560)
        hardware.nvidia.open = true;
      }
    )

    # WORKAROUND: Manually set home-manager config until mynixos Phase 2.2 is complete
    # mynixos should auto-generate this from my.users, but it's not implemented yet
    {
      home-manager.users.logger = {
        home.stateVersion = "25.05";
      };

      # Package overlays
      nixpkgs.overlays = [
        (import ../../overlays/opencode.nix)
      ];
    }
  ];
}
