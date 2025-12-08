{ mynixos, secrets, ... }:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = {
    # System configuration
    system = {
      enable = true;
      hostname = "yoga";
      # kernel defaults to mynixos system module (linuxPackages_latest)
      # Override with: kernel = pkgs.linuxPackages_6_12; (or any other kernel package)
    };

    # Hardware configuration
    hardware = {
      # Motherboard (automatically sets cpu/gpu/bluetooth/audio)
      motherboards.gigabyte.x870e-aorus-elite-wifi7 = {
        enable = true;
        bluetooth.enable = false;
        networking = {
          enable = true;
          useDHCP = true;
          wireless = {
            enable = false;
            useDHCP = true;
          };
        };
        storage.nvme.enable = true;
      };

      # Cooling
      cooling.nzxt.kraken-elite-rgb.elite-240-rgb = {
        enable = true;
        lcd = {
          enable = true;
          brightness = 100;
        };

        rgb.enable = true;
        liquidctl = {
          enable = true;
          autoInitialize = false;
        };

        monitoring.enable = true;
      };

      # Peripherals
      peripherals.elgato.streamdeck.enable = true;
    };

    # Filesystem configuration
    filesystem = {
      type = "disko";
      config = ./disko.nix;
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

    # Security: System-level (affects bootloader, kernel, PAM, audit)
    # - secureBoot: Kernel signing and bootloader (lanzaboote)
    # - yubikey: System services (pcscd, udev, PAM), per-user keys handled automatically
    # - auditRules: Kernel syscall monitoring for compliance
    security = {
      enable = true;
      secureBoot.enable = true;
      yubikey.enable = true;
      auditRules.enable = true;
    };

    # Secrets management via sops-nix
    # Encrypted secrets stored in ~/.secrets/secrets.yaml (private, not in public repo)
    # Decrypted at activation using host-specific age key (GPG/YubiKey used for encryption only)
    # Age key must be at runtime path (not nix store) - copy from ~/.secrets/hosts/yoga/age-key.txt
    secrets = {
      enable = true;
      defaultSopsFile = "${secrets}/secrets.yaml";
      ageKeyFile = "/persist/etc/sops-age-keys.txt";
    };

    # Infrastructure: System-level services and infrastructure
    # - docker: Rootless containerization (auto-enabled by user dev feature)
    # - binfmt: Cross-platform emulation (ARM, AppImage)
    # - k3s: Kubernetes cluster infrastructure
    # - github-runner: Self-hosted Actions runners on k3s
    # Note: direnv and vscode moved to per-user apps (my.users.<name>.apps.dev)
    infra = {
      github-runner = {
        enable = false;
        enableGpu = true;
      };
    };

    # Video/Streaming: System-level video infrastructure
    # - Virtual camera (v4l2loopback) - auto-enabled when user has graphical.streaming.enable = true
    # Note: OBS is per-user in my.users.<name>.graphical.streaming
    # Note: StreamDeck moved to my.hardware.peripherals.elgato.streamdeck
    video = {
      # Temporarily disabled due to v4l2loopback kernel 6.18 incompatibility
      virtual.enable = false; # Auto-enabled by user streaming flag, but disabled due to kernel 6.18 incompatibility
    };

    # AI configuration
    ai = {
      enable = true;
      # mcpServers is now configured per-user in my.users.<name>.ai.mcpServers
    };

    # Performance configuration
    performance = {
      enable = true;
      zramPercent = 15;
      vmtouchCache = true;
    };

    # Storage configuration (impermanence + disko)
    # TODO: shouldn't this move to the user's? my.users.<user>.storage.impermanence ? it should enable system level storage .imperrmanence that the user can override if needed to
    storage.impermanence = {
      enable = true;
      useDedicatedPartition = true; # yoga has dedicated /persist partition
      persistUserData = true;
      cloneFlakeRepo = "git@github.com:i-am-logger/flake.git";
      symlinkFlakeToHome = true; # Automatically create ~/.flake symlink for all users (auto-detected from my.users)
    };

    # Personal user data (for mynixos features)
    # User definitions are imported from /etc/nixos/users/
    users =
      let
        baseUsers = import ../../users;
      in
      baseUsers
      // {
        # System-specific GitHub overrides for yoga
        logger = baseUsers.logger // {
          github = baseUsers.logger.github // {
            repositories = [ "loial" "logger" "pds" ];
          };
        };
      };

    # Hardware specs (cpu, gpu, bluetooth, audio) are defined in the motherboard module
    # Cooling (Kraken Elite 240 RGB) is imported in hardware array above

  };

  # WORKAROUND: Manually set home-manager config until mynixos Phase 2.2 is complete
  # mynixos should auto-generate this from my.users, but it's not implemented yet
  extraModules = [
    {
      home-manager.users.logger = {
        home.stateVersion = "25.05";
      };
    }
  ];
}
