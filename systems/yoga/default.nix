{ mynixos
, secrets
, claude-desktop ? null
, yoga-kernel
, openrgb-src
, ...
}:

mynixos.lib.mkSystem {

  # Direct mynixos configuration
  my = [
    {
      # System configuration
      system = {
        # What `rebuild-system update` re-pins before it builds. Named one by
        # one on purpose -- scripts/ also holds update-all-git-repos.sh and
        # update-master-from-old-commit.sh, which are not overlay updaters.
        update.scripts = [
          "scripts/update-claude-code.sh"
          "scripts/update-herdr.sh"
        ];

        enable = true;
        hostname = "yoga";

        # Local checkouts the rebuild scripts prefer over the lock, when the
        # path is actually on this machine. vogix is reached through mynixos,
        # so it needs the nested input path rather than a bare name.
        localInputs = {
          mynixos = "/home/logger/Code/github/logger/mynixos";
          "mynixos/vogix" = "/home/logger/Code/github/logger/vogix";
        };
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
        peripherals.apple.dfu.enable = true;
        peripherals.elgato.streamdeck.enable = true;
        peripherals.keychron.k2-he.enable = true;
        peripherals.sipeed.tangPrimer25k.enable = true;
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

        # IPv6 privacy (temp addresses rotating every ~90s–2min, 10 min valid
        # window for in-flight connections) is stated by mynixos' own defaults
        # -- my.network.ipv6.privacy is 120/600/30 -- so this host sets nothing.
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

      # qobine needs a paid Qobuz subscription, so it is enabled per host rather
      # than in the shared user profile. `qobine-tui login` authenticates through
      # the browser; the resulting token, queue and settings live in
      # ~/.local/share/qobine, which the app option registers with impermanence.
      users.logger.apps.media.players.qobine.enable = true;
    }
  ];

  extraModules = [
    (
      _:
      {
        # claude-desktop is passed as null by flake.nix until upstream stops
        # depending on the removed nodePackages.asar, so this list is empty in
        # practice -- the conditional is what survives the day it is non-null.
        environment.systemPackages =
          if claude-desktop != null then
            [ claude-desktop.packages.x86_64-linux.claude-desktop-with-fhs ]
          else
            [ ];

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
          (import ../../overlays/herdr.nix)
          # Build OpenRGB from the local perf/cli-latency branch (overlays/openrgb.nix
          # + the openrgb-src flake input) so vogix's server and the openrgb CLI resolve
          # to our build instead of nixpkgs' 1.0rc2.
          (import ../../overlays/openrgb.nix openrgb-src.outPath)
        ];
      }
    )

    # DDR5 modules on this build carry addressable RGB (ENE controllers). DRAM RGB
    # is its own hardware -- it travels with the sticks, independent of the board
    # and the keyboard -- and is driven by OpenRGB, which lives in vogix. So flip
    # vogix's dram-rgb hardware module on directly (it pulls in OpenRGB + the
    # chipset SMBus stack on its own).
    { vogix.hardware.dram-rgb.enable = true; }

    # TEST (amdgpu event-driven branch): a non-default boot entry carrying four
    # amdgpu patches on the stock 7.1 kernel:
    #   1. hold page tables until their TLB flush completes -- GPUVM
    #      free-after-flush ordering tied to the flush-completion event rather
    #      than a timeout-prone KIQ flush;
    #   2. handle non-retry VM faults from the soft IH ring -- moves non-retry
    #      fault processing off the non-threaded hard IRQ so a sustained fault
    #      storm can no longer livelock the CPU and halt the machine;
    #   3. attribute a contained ring reset to the faulting context -- a
    #      bystander starved into a timeout by another context's fault storm is
    #      no longer branded guilty and torn down;
    #   4. recover a storm-wedged bystander without a full-device reset, falling
    #      back to a direct-MMIO (KIQ-bypass) queue reset when the per-queue
    #      path would stall through a jammed KIQ and force a fence-killing
    #      MODE2. A live culprit is reset by vmid at its source; full reset
    #      stays the last resort.
    # The unpatched kernel stays the default; select the "amdgpu-vm-tlb-test"
    # entry at the bootloader to run the patched kernel. Remove once validated.
    ({ pkgs, ... }: {
      specialisation.amdgpu-vm-tlb-test.configuration = {
        # Build the kernel from the local amdgpu branch via the git+file
        # `yoga-kernel` input, instead of exported .patch files. Iterate: commit
        # on the branch, `nix flake update yoga-kernel`, then rebuild.
        my.system.kernel.localSource = {
          src = yoga-kernel.outPath;
          base = pkgs.linux_7_1;
          version = "7.1.0";
        };
        # Run the amdgpu KUnit suite at boot (KTAP results in dmesg) so the
        # event-driven fault-recovery unit tests are validated on this test
        # kernel. Config-only entry, no patch.
        boot.kernelPatches = [
          {
            name = "amdgpu-kunit-tests";
            patch = null;
            extraConfig = ''
              KUNIT y
              DRM_AMDGPU_KUNIT_TEST y
            '';
          }
        ];
      };
    })
  ];
}
