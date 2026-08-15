{ mynixos, ... }:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = [
    {
      # System configuration
      # Windows dual-boot: local-time hardware clock + NTFS support.
      system.dualBoot.windows = true;

      system = {
        enable = true;
        hostname = "skyspy-dev";
        # kernel defaults to mynixos system module (linuxPackages_latest)
        # Overridden in extraModules below to use linuxPackages_6_12 for NVIDIA compatibility
      };

      # Hardware configuration (laptop automatically sets cpu/gpu/bluetooth/audio)
      hardware = {
        # YubiKey device support (pcscd, udev, PAM, gnupg agent). Moved out of
        # my.security — it is device wiring, not policy.
        securityKeys.yubico.enable = true;

        laptops.lenovo.legion-16irx8h.enable = true;

        # Peripherals
        peripherals.elgato.streamdeck.enable = true;
      };

      # Filesystem configuration
      filesystem = {
        type = "nixos";
        config = ./filesystem.nix;
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
      # Virtual camera (v4l2loopback) for OBS, auto-enabled by the user's
      # graphical.streaming flag.
      video.virtual.enable = true;

      # Network: Tailscale SaaS (controlPlane defaults to "tailscale"). The
      # .onion login-server this block used to wait for was retired with the
      # headscale design -- the Tor client below existed only to reach it and
      # went with it.
      network = {
        tailscale = {
          enable = true;
          # Tailnet-identity ssh in, same as yoga; classic sshd + YubiKey
          # pubkeys stays live on tailscale0 as the fallback path.
          ssh = true;
          useRoutingFeatures = "client";
        };

        # IPv6 privacy (temp addresses rotating every ~90s–2min, 10 min valid
        # window for in-flight connections) is stated by mynixos' own defaults
        # -- my.network.ipv6.privacy is 120/600/30 -- so this host sets nothing.
      };

      # AI configuration
      ai = {
        enable = false; # Ollama disabled on skyspy-dev
        # mcpServers is now configured per-user in my.users.<name>.ai.mcpServers
      };

      # Performance configuration
      performance.enable = true;

      # Storage configuration (impermanence + disko)
      storage.impermanence = {
        enable = true;
        useDedicatedPartition = false; # skyspy-dev uses tmpfiles, not dedicated partition
        cloneFlakeRepo = "git@github.com:i-am-logger/flake.git";
        symlinkFlakeToHome = true; # Automatically create ~/.flake symlink for all users (auto-detected from my.users)
        # Custom directories (applied to all users)
        extraUserDirectories = [ "GitHub" ]; # skyspy-dev uses GitHub instead of Code
      };

      # Personal user data, shared verbatim with every host. Facts that are true
      # only here go in the second `my` layer at the bottom of this file.
      users = import ../../users;

      # Hardware specs (cpu, gpu, bluetooth, audio) are defined in the laptop module
    }

    # Second layer — see the note in systems/yoga/default.nix. `mounts` is a
    # listOf, so this appends rather than replaces.
    {
      users.logger.mounts = [
        {
          mountPoint = "/home/logger/mnt/windows";
          device = "A03C41603C413318"; # Prefixed with /dev/disk/by-uuid/
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
    }
  ];

  # System-specific configuration (personal, not opinionated)
  extraModules = [
    # Tripwire: Hyprland 0.57 removes hyprlang configs AND the `keyword`/legacy
    # `dispatch` IPC (hyprwm/Hyprland#15539). Same rationale as on yoga: fail
    # the build until the Lua migration lands (thread_hyprland_lua_migration).
    ({ config, lib, ... }: {
      assertions = [{
        assertion = lib.versionOlder config.programs.hyprland.package.version "0.57";
        message = ''
          Hyprland ${config.programs.hyprland.package.version} drops hyprlang configs and
          the legacy hyprctl IPC that vogix depends on. Do not switch until the
          Lua migration is done (thread_hyprland_lua_migration), or pin
          hyprland to 0.56.x via an overlay for this update.
        '';
      }];
    })

    # Kernel pinned to 6.12 for the NVIDIA open driver: later kernels changed the
    # get_dev_pagemap API and the open modules fail to compile against them.
    # Can be removed once NVIDIA driver is updated to support kernel 6.18
    (
      { pkgs, lib, ... }:
      {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;

        # Use NVIDIA open source kernel modules (required for driver >= 560)
        hardware.nvidia.open = true;
      }
    )

    {
      home-manager.users.logger = {
        # Pinned below the mynixos default of 26.11: this host's home directory
        # was created under 25.05 and home-manager keys migration behaviour off
        # this value, so raising it would re-run migrations against existing state.
        home.stateVersion = "25.05";
      };

      # Package overlays
      nixpkgs.overlays = [
        (import ../../overlays/claude-code.nix)
      ];
    }
  ];
}
