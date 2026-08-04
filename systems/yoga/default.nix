{ mynixos
, secrets
, claude-desktop ? null
, ...
}:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = [
    {
      # System configuration
      system = {
        enable = true;
        hostname = "yoga";
        # kernel defaults to mynixos system module (linuxPackages_latest)
        # Override with: kernel = pkgs.linuxPackages_6_12; (or any other kernel package)
      };

      # Hardware configuration
      hardware = {
        # YubiKey device support (pcscd, udev, PAM, gnupg agent). Moved out of
        # my.security — it is device wiring, not policy.
        securityKeys.yubico.enable = true;

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
        peripherals.keychron.k2-he.enable = true;
      };

      # Filesystem configuration
      filesystem = {
        type = "disko";
        config = ./disko.nix;
      };

      # theming.enable defaults to true, with vogix as the theme system. vogix is
      # the only one mynixos has.

      # Environment configuration
      environment = {
        enable = true;
        xdg.enable = true;

        # Login via greetd + tuigreet instead of GDM. GDM is gnome-shell and
        # couples this Hyprland host to the whole GNOME stack — the GNOME 50 bump
        # broke its greeter ("Session never registered") and removed gdm.wayland.
        # greetd is the Hyprland-recommended, GNOME-free, fast, low-flash login;
        # tuigreet is text (no greeter-compositor → least screen flashing) and
        # launches Hyprland directly. A graphical, vogix-themed greeter (ReGreet
        # as a vogix surface) can layer on later if we want the looks.
        displayManager.type = "greetd";

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
        # No TPM-bound FDE here, so suppress systemd's SRK/NvPCR (measured-boot)
        # setup and sweep the stale nvpcr-anchor creds it leaves on the ESP — those
        # are what PID1 reports as "untrusted credentials" each boot. Flip to true
        # if this box ever adopts TPM-sealed disk unlock.
        tpm.enable = false;
        auditRules.enable = true;
        nopasswdRebuild = true;
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
      # Virtual camera (v4l2loopback) for OBS. Auto-enabled by the user's
      # graphical.streaming flag; stated here so the host owns the decision.
      video.virtual.enable = true;

      # Network: Headscale mesh VPN + Tor hidden service
      network = {
        headscale = {
          enable = true;
          port = 8090;
          users = [
            "logger"
            "logger-mobile"
          ];
          acl = {
            groups = {
              "group:admin" = [ "logger@" ];
              "group:mobile" = [ "logger-mobile@" ];
            };
            tagOwners = {
              "tag:server" = [ "group:admin" ];
            };
            rules = [
              {
                action = "accept";
                src = [ "group:admin" ];
                dst = [ "*:*" ];
              }
              {
                action = "accept";
                src = [ "group:mobile" ];
                dst = [ "tag:server:3000" ];
              }
            ];
          };
        };
        tailscale = {
          enable = false;
          exitNode = true;
          useRoutingFeatures = "server";
          allowedTCPPorts = [
            18789 # openclaw gateway
          ];
        };
        tor.enable = false;

        # Aggressive IPv6 privacy: rotate temp addresses every ~90s–2min,
        # 10 min valid window for in-flight connections.
      };

      # AI configuration
      ai = {
        enable = true;
        ollama.enable = false; # No dGPU — using claude-proxy instead
        claudeCodeProxy = {
          enable = true;
          model = "opus";
        };
        openclaw = {
          enable = false;
        };
      };

      # Performance configuration
      performance.enable = true;

      # Storage configuration (impermanence + disko)
      # TODO: shouldn't this move to the user's? my.users.<user>.storage.impermanence ? it should enable system level storage .imperrmanence that the user can override if needed to
      storage.impermanence = {
        enable = true;
        useDedicatedPartition = true; # yoga has dedicated /persist partition
        cloneFlakeRepo = "git@github.com:i-am-logger/flake.git";
        symlinkFlakeToHome = true; # Automatically create ~/.flake symlink for all users (auto-detected from my.users)
      };

      # Personal user data, shared verbatim with every host. Facts that are true
      # only here go in the second `my` layer at the bottom of this file.
      users = import ../../users;

      # Hardware specs (cpu, gpu, bluetooth, audio) are defined in the motherboard module
      # Cooling (Kraken Elite 240 RGB) is imported in hardware array above

    }

    # Second layer. The module system merges the layers per option using each
    # option's own type, so this adds to the shared profile rather than replacing
    # the attrset that holds it — `github.username` survives, and `repositories`
    # being a listOf means these CONCATENATE onto anything already defined.
    {
      users.logger.github.repositories = [
        "loial"
        "logger"
        "pds"
      ];
    }
  ];

  extraModules = [
    (
      { pkgs, ... }:
      {
        environment.systemPackages =
          with pkgs;
          [
            # warp-terminal
          ]
          ++ (
            if claude-desktop != null then
              [ claude-desktop.packages.x86_64-linux.claude-desktop-with-fhs ]
            else
              [ ]
          );

        # vogix is the sole input engine (kanata removed): uinput + the
        # input/uinput group wiring and the vogix-input user service are
        # unconditional now, so this host needs no engine toggle.
        home-manager.users.logger = {
          # Debug logging for the vogix input engine + daemon, persisted to
          # journald (RUST_LOG=vogix=debug on both units). Makes every keybinding
          # decision and the daemon's startup env visible:
          #   journalctl --user -u vogix-input -u vogix-daemon -f
          programs.vogix.logLevel = "debug";
        };

        # /etc/machine-id is deliberately NOT persisted. A fresh id each boot is
        # the point: machine-id is a stable, unsalted identifier that anything
        # local can read, so persisting it would hand every reboot the same
        # fingerprint. The cost is that `journalctl -b -1` cannot find the
        # previous boot by default -- earlier boots are still readable with
        # `journalctl --directory=/var/log/journal/<machine-id>`.

        # Package overlays (liquidctl is now managed by vogix)
        nixpkgs.overlays = [
          (import ../../overlays/claude-code.nix)
        ];
      }
    )

    # DDR5 modules on this build carry addressable RGB (ENE controllers). DRAM RGB
    # is its own hardware -- it travels with the sticks, independent of the board
    # and the keyboard -- and is driven by OpenRGB, which lives in vogix. So flip
    # vogix's dram-rgb hardware module on directly (it pulls in OpenRGB + the
    # chipset SMBus stack on its own).
    { vogix.hardware.dram-rgb.enable = true; }
  ];
}
