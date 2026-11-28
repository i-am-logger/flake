{ mynixos, ... }:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = [
    {
      # System configuration
      # Windows dual-boot: local-time hardware clock + NTFS support.
      system.dualBoot.windows = true;

      system = {
        # What `rebuild-system update` re-pins before it builds. Named one by
        # one on purpose -- scripts/ also holds update-all-git-repos.sh and
        # update-master-from-old-commit.sh, which are not overlay updaters.
        update.scripts = [
          "scripts/update-claude-code.sh"
          "scripts/update-herdr.sh"
        ];

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

        # Login: greetd+tuigreet (text). The vogix SDDM greeter is parked here
        # too — its teardown races this NVIDIA host's modeset and freezes
        # Hyprland right after login. Restore backend = "sddm" / look = "vogix"
        # once that race is fixed.
        login = {
          backend = "greetd";
          look = "stock";
        };

        motd = {
          enable = true;
          content = builtins.readFile ../motd.txt;
        };
      };

      # Security configuration — same policy as yoga. Secure Boot runs through
      # lanzaboote, signed with the keys already enrolled in this machine's
      # firmware and persisted at /var/lib/sbctl.
      security = {
        enable = true;
        secureBoot.enable = true;
        auditRules.enable = true;
        nopasswdRebuild = true;
      };

      # Infrastructure configuration
      # - containers: Rootless podman, auto-enabled by user dev feature
      # - github-runner: Disabled
      # Note: direnv and vscode are now per-user apps (my.users.<name>.apps.dev)
      #
      # `k3s.enable = false` stood here and went with the option: mynixos
      # replaced my.infra.k3s with my.infra.rke2. Setting an option to false
      # still requires it to exist, so that line broke THIS host's evaluation
      # while yoga -- which mentioned k3s only in a comment -- kept building.
      # The cluster is not configured here yet; that lands with the rest of the
      # fleet's RKE2 wiring.
      infra = {
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

      # AI configuration — same as yoga: no local ollama, Claude through the
      # proxy. mcpServers is per-user in my.users.<name>.ai.mcpServers.
      ai = {
        enable = true;
        ollama.enable = false;
        claudeCodeProxy = {
          enable = true;
          model = "opus";
        };
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

    # Second layer — see the note in systems/yoga/default.nix. `mounts` and
    # `repositories` are listOf, so these append rather than replace.
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

      users.logger.github.repositories = [
        "loial"
        "logger"
        "pds"
      ];

      # qobine needs a paid Qobuz subscription, so it is enabled per host rather
      # than in the shared user profile — same as yoga.
      users.logger.apps.media.players.qobine.enable = true;

      # The Lua config engine, mynixos's default since 0.28 and the only one
      # Hyprland ≥0.57 accepts; stated here as the host's own fact.
      users.logger.apps.graphical.windowManagers.hyprland.configType = "lua";

      # External display over HDMI. The port is wired to the NVIDIA dGPU, and
      # the attached Alienware AW3225QF advertises 4K120 over FRL — but the
      # cable in use is a High Speed (HDMI 1.4 class, ~340 MHz) one, so the
      # link only trains at low TMDS rates. mynixos' wildcard rule asks for
      # `highres`, which picks 3840x2160@60 (594 MHz); that never trains, so
      # the monitor sits at "No Signal" while the compositor renders into it
      # regardless. 2560x1440@60 is 241.5 MHz, trains reliably, and is the
      # panel's own 16:9 aspect so it fills the screen edge to edge.
      #
      # The external is the mirror SOURCE and the laptop follows it: mirroring
      # the other way puts the panel's 16:10 2560x1600 inside a 16:9 frame and
      # pillarboxes the external. This way the external is pixel-exact and the
      # 16:10 laptop is the one that letterboxes.
      #
      # The mirror pair stays 8-bit SDR: the external link cannot carry more,
      # and the laptop shows the same frame. Swap in an Ultra High Speed
      # (48 Gbps) cable and `external` can drop its mode/bitDepth/hdr lines to
      # get the model's defaults (highres, 10-bit HDR) back.
      hardware.display = {
        monitors.dell.aw3225qf.external = {
          output = "HDMI-A-1";
          mode = { width = 2560; height = 1440; refresh = 59.95; };
          bitDepth = 8;
          hdr.enable = false;
        };
        monitors.generic.laptop = {
          output = "eDP-1";
          mode = { width = 2560; height = 1600; refresh = 240; };
          bitDepth = 8;
          hdr.enable = false;
        };
        layout = {
          external.position = { x = 0; y = 0; };
          laptop.mirror = "external";
        };
      };
    }
  ];

  # System-specific configuration (personal, not opinionated)
  extraModules = [
    ../nix-trust.nix # Nix trusts root only; devenv's cache (S2a)
    # THIS HOST KEEPS A MUTABLE ACCOUNT DATABASE, and must say so.
    #
    # mynixos defaults users.mutableUsers = false (my/users/users), which is
    # right for every host whose password is declarative. This one's is not:
    # my.secrets is off here, users/logger states no hashedPassword, and the
    # password was set with `passwd` and has simply survived -- legitimately,
    # because unlike yoga and ads-dev1 this root is REAL EXT4 (see
    # ./filesystem.nix) and nothing wipes it.
    #
    # Taking the default here would NOT fail the build: logger is in wheel and
    # carries YubiKey authorized_keys, so nixpkgs' lockout assertion is
    # satisfied by the KEYS. It would instead let update-users-groups.pl
    # rewrite the password field to `!` on the next activation -- locking the
    # console while ssh kept working, which is the hardest version of this
    # failure to diagnose.
    #
    # Remove this once the password has a declarative source: give this host
    # my.secrets as yoga has, and users/logger's
    # linux.secrets.hashedPassword = true starts applying on its own.
    { users.mutableUsers = true; }

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

    # Stays on wezterm while mynixos defaults TERMINAL to baud: this host's
    # switch is on hold. Here rather than in `my`, which has no pkgs in scope.
    (
      { pkgs, ... }:
      {
        my.users.logger.environment.TERMINAL = pkgs.wezterm;
      }
    )

    {
      home-manager.users.logger = {
        # Pinned below the mynixos default of 26.11: this host's home directory
        # was created under 25.05 and home-manager keys migration behaviour off
        # this value, so raising it would re-run migrations against existing state.
        home.stateVersion = "25.05";

        # Debug logging for the vogix input engine + daemon, same as yoga:
        #   journalctl --user -u vogix-input -u vogix-daemon -f
        programs.vogix.logLevel = "debug";
      };

      # Package overlays
      nixpkgs.overlays = [
        (import ../../overlays/claude-code.nix)
        (import ../../overlays/herdr.nix)
      ];
    }
  ];
}
