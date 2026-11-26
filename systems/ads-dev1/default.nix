# ads-dev1 -- AMD Threadripper workstation on a Gigabyte TRX50 AERO D.
#
# A yoga-class machine: the same domains, the same user profile, the same
# impermanence-on-tmpfs shape. What differs is hardware and nothing else, which
# is the point of the motherboard profile this enables: 64 cores, 187 GiB, a
# DISCRETE RDNA4 card rather than yoga's iGPU, and one 8 TB NVMe instead of
# yoga's partitioned pair.
#
# STAGED FIRST INSTALL. Secure boot and sops are both OFF here, and that is
# deliberate rather than unfinished -- each needs provisioning that cannot happen
# before the machine exists (sbctl keys enrolled in firmware Setup Mode; an age
# key and secrets.yaml on /persist). Turning them on is a second switch, where a
# failure is unambiguous. See the GATES at the bottom of this file.
{ mynixos
, ...
}:

mynixos.lib.mkSystem {

  my = [
    {
      system = {
        update.scripts = [
          "scripts/update-claude-code.sh"
          "scripts/update-herdr.sh"
        ];

        enable = true;
        hostname = "ads-dev1";
        etcNixos.link = "/home/logger/Code/logger/flake";

        localInputs = {
          mynixos = "/home/logger/Code/logger/mynixos";
          "mynixos/vogix" = "/home/logger/Code/logger/vogix";
        };
      };

      hardware = {
        securityKeys.yubico.enable = true;
        # yubikey3 lives in this machine: only its key is offered to SSH, so an
        # absent card is never asked for, and it is gpg's default-key.
        securityKeys.residentSerials = [ "15147046" ];

        # Dell AW3225QF on DisplayPort: 3840x2160@240, 10-bit HDR through DSC.
        display.monitors.dell.aw3225qf.main = { };

        # Corsair HX1200i Series 2025: rails, power, fan and temps in `sensors`.
        powerSupplies.corsair.hx1200i.enable = true;

        # Logi Bolt receiver (the mouse): Solaar in the tray for pairing,
        # battery and button settings.
        peripherals.logitech.bolt.enable = true;

        # Elgato Game Capture 4K X on USB (telly's source): vendor controls
        # (HDR tone mapping, EDID mode) usable without sudo.
        peripherals.elgato.game-capture-4k-x.enable = true;

        # Gigabyte TRX50 AERO D (sTR5, AMD TRX50). Sets cpu/gpu = "amd",
        # hostPlatform, and the storage/usb/memory component modules. Unlike
        # yoga's X870E this board carries no GPU quirks: Threadripper has no
        # iGPU, so the only display adapter is the discrete RX 9070 XT and the
        # generic my/hardware/gpu/amd module is the whole story.
        motherboards.gigabyte.trx50-aero-d = {
          enable = true;
          # The Qualcomm WCN785x has a working BT radio (hci0 comes up on the
          # live CD), but nothing here wants it yet -- same answer as yoga.
          bluetooth.enable = false;
          networking = {
            enable = true;
            useDHCP = true;
            # NetworkManager drives the Wi-Fi 7 radio, not
            # networking.wireless/wpa_supplicant.
            wireless = {
              enable = false;
              useDHCP = true;
            };
          };
          storage.nvme.enable = true;
        };

        # NO cooling module: there is no NZXT Kraken in this box. The Corsair
        # HX1200i is read by the in-kernel corsairpsu hwmon with no
        # configuration, so it needs nothing here either.
        #
        # NO elgato.streamdeck: not in this machine.
        peripherals.keychron.k2-he.enable = true;
        peripherals.apple.dfu.enable = true;
        peripherals.sipeed.tangPrimer25k.enable = true;
      };

      filesystem = {
        type = "disko";
        config = ./disko.nix;
      };

      environment = {
        enable = true;
        xdg.enable = true;

        # greetd+tuigreet, matching yoga. yoga parks the vogix SDDM greeter
        # because its teardown races that host's amdgpu CRTC-disable path -- this
        # is different silicon (RDNA4, not Raphael RDNA2), so the race may simply
        # not exist here. The login-vogix specialisation below is how to find out
        # without making login the thing that breaks.
        login = {
          backend = "greetd";
          look = "stock";
        };

        motd = {
          enable = true;
          content = builtins.readFile ../motd.txt;
        };

        # timezone left unsaid -> the mynixos default, America/Denver, as yoga.
      };

      security = {
        enable = true;

        # GATE B. OFF for the first install: lanzaboote needs sbctl keys created
        # and enrolled with the firmware in Setup Mode, which cannot happen
        # before the machine boots. With this false, my/hardware/boot/uefi
        # enables systemd-boot instead -- which is why this host's motherboard
        # profile does NOT carry the X870E profile's unconditional
        # `systemd-boot.enable = mkForce false`.
        secureBoot.enable = false;

        # This board HAS a TPM (/dev/tpm0), unlike yoga. Still false: there is no
        # TPM-bound FDE here, and leaving it on without one is what leaves stale
        # NvPCR anchor credentials on the ESP for PID1 to report as "untrusted
        # credentials" every boot. Flip it if this box ever adopts TPM-sealed
        # disk unlock.
        tpm.enable = false;

        auditRules.enable = true;
        nopasswdRebuild = true;

        # No sshAgentSudo: that option exists to keep a YubiKey that LIVES in the
        # machine from being what authorizes sudo on it. No key is resident here
        # yet, so there is nothing to exclude. GATE D.
      };

      # No my.secrets. GATE C -- see the bottom of this file. Nothing decrypts
      # until /persist/etc/sops/secrets.yaml and the host age key exist, and
      # neither can be written before the disk does.

      infra = {
        github-runner = {
          enable = false;
          enableGpu = true;
        };
      };

      video.virtual.enable = true;

      # Engines and workloads. Rootless podman is on by default (logger wants
      # containers), so it is not written here.
      virtualisation = {
        # System containers and VMs, with the web UI on localhost:8443 (reach
        # it over SSH or tailscale serve). incus-admin and libvirtd are both
        # root-equivalent, hence the explicit names. /persist is btrfs, so the
        # pool gets snapshots and instant copies.
        incus = {
          enable = true;
          users = [ "logger" ];
          storage = "btrfs";
          ui.enable = true;
        };

        vms = {
          libvirt = {
            enable = true;
            users = [ "logger" ];
          };

          # For vendor tools with no Linux build: the AW3225QF's firmware
          # updater, with the monitor's USB passed through once the cable is
          # in (its id goes in `usb`). The ISO is pinned by hash and lives with
          # the VM: `vm-windows fetch ~/Downloads/Windows11_Client_x64_en-us_26300_9457.iso`
          # places it (reflinked, instant), then `vm-windows` starts the
          # unattended setup, which needs no Microsoft account.
          machines.windows = {
            owner = "logger";
            os = "windows";
            # Windows11_Client_x64_en-us_26300_9457.iso
            install.iso.sha256 = "bd4307df32bc8af33b39ccecb1174aeb345386630f89a2b86c7a4e36b55ea650";
            cpus = 4;
            memory = "8G";
            disk.size = "64G";
          };
        };
      };

      network = {
        tailscale = {
          enable = true; # controlPlane defaults to "tailscale" (SaaS)
          ssh = true;
          # No relayServerPort: that exists on yoga for the container roles it
          # NATs, and this host runs none yet. GATE E.
        };
        tor.enable = false;
      };

      ai = {
        enable = true;
        claudeCodeProxy = {
          enable = true;
          model = "opus";
        };

        # yoga disables ollama with "no dGPU". This box has one: an RX 9070 XT,
        # 16 GB, Navi 48.
        ollama = {
          enable = false; # off for now; the settings below stay for when it returns
          acceleration = "rocm";
          # gfx1201 is Navi 48. The mynixos default (11.0.2) is RDNA3 and would
          # make ROCm claim the wrong ISA on this card. The value becomes
          # HSA_OVERRIDE_GFX_VERSION and selects pkgs.ollama-rocm.
          rocmGfxVersion = "12.0.1";
        };

        openclaw.enable = false;
      };

      performance.enable = true;
      # MemoryMax of the user runs.slice releasable's runs share (no swap,
      # outside systemd-oomd): 128G of this host's 187 GiB.
      performance.runs.budget = "128G";

      storage.impermanence = {
        enable = true;
        # /persist is its own mount (a btrfs subvolume of the single pool), so
        # impermanence marks it neededForBoot rather than creating it with
        # tmpfiles.
        useDedicatedPartition = true;
        symlinkFlakeToHome = true;
      };

      users = import ../../users;
    }

    # Second layer. Merged per option by the module system, so `listOf` options
    # CONCATENATE onto the shared profile rather than replacing it.
    {
      users.logger.github.repositories = [
        "loial"
        "logger"
        "pds"
      ];

      users.logger.apps.media.players.qobine.enable = true;
      users.logger.input.inputMethod.type = "fcitx5";
      # fleetd wakes on new fleet mail at once instead of on its 300 s round.
      users.logger.apps.ai.tools.claude-code.fleetWake.enable = true;

      # The Lua config engine. yoga flipped first and it has held, so this host
      # starts there rather than migrating later.
      users.logger.apps.graphical.windowManagers.hyprland.configType = "lua";

      # GATE A: the first-boot password. /etc/shadow is NOT in impermanence's
      # persisted set, and with my.secrets off there is no hashedPasswordFile --
      # so without a hash stated here, logger has no password and the first
      # reboot locks everyone out. DELETE THIS LINE when GATE C lands;
      # users/logger already sets linux.secrets.hashedPassword = true, which is
      # inert while my.secrets is off and takes priority the moment it is on.
      # GATE A: the first-boot password, as a RUNTIME FILE rather than a hash in
      # this repo.
      #
      # /etc/shadow is not in impermanence's persisted set and this root is a
      # tmpfs, so the account database is rebuilt from config every boot. With
      # my.secrets not yet provisioned (GATE C) there is no sops
      # hashedPasswordFile, so without something here logger has no password at
      # all and the first reboot locks everyone out. mynixos now defaults
      # users.mutableUsers = false, so `passwd` cannot rescue it either -- which
      # is the honest behaviour, not a regression.
      #
      # A literal hashedPassword would work and is NOT used: this repo is public,
      # and a sha-512 crypt hash in it is an offline cracking target forever,
      # surviving in history long after the password is rotated. A path keeps the
      # material on this machine only -- the same reason my.secrets refuses store
      # paths. Written out of band during the install; see docs below.
      #
      # DELETE THIS LINE at GATE C. users/logger already sets
      # linux.secrets.hashedPassword = true, which is inert while my.secrets is
      # off and takes priority the moment it is on -- and mynixos' getPasswordFile
      # prefers an explicit hashedPasswordFile over the sops secret, so leaving
      # this in place would silently outrank sops.
      users.logger.hashedPasswordFile = "/persist/etc/logger-password-hash";
    }
  ];

  extraModules = [
    # This flake's claude-code and herdr in place of nixpkgs'. Overlays are
    # applied per host in this repo rather than globally in flake.nix.
    (_: {
      nixpkgs.overlays = [
        (import ../../overlays/claude-code.nix)
        (import ../../overlays/herdr.nix)
      ];
    })

    # NixOS's default perl and strace, which mynixos no longer ships
    # (defaultPackages = [ rsync ]): baud's scripts/vt-child.sh runs host perl,
    # and measure traces read sizes with strace.
    ({ pkgs, ... }: {
      environment.systemPackages = [ pkgs.perl pkgs.strace ];
    })

    # btrfs checksums every extent but only VERIFIES a checksum when the extent
    # is read or scrubbed. Without a scrub, rot on a multi-terabyte /persist is
    # discovered the day you open the file -- which is the day it is already too
    # late. Monthly, on the one pool (both mountpoints are subvolumes of it, so
    # scrubbing either scrubs the device; both are named so the intent survives a
    # future split).
    {
      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/nix" "/persist" ];
      };
    }

    # A non-default boot entry carrying the vogix SDDM greeter. Login must never
    # be the thing that bricks, so greetd stays the default and this is how the
    # vogix greeter gets tested on RDNA4 -- the CRTC handoff race that parked it
    # on yoga is specific to that host's amdgpu path and may not exist here.
    ({ lib, ... }: {
      # mkForce: a specialisation MERGES with the base config, and the base pins
      # greetd/stock at normal priority.
      specialisation.login-vogix.configuration = {
        my.environment.login = {
          backend = lib.mkForce "sddm";
          look = lib.mkForce "vogix";
        };
      };
    })
  ];
}

# GATES -- the staged bring-up, each its own switch so a failure names itself.
#
#   A  First-boot password (above). Replace the placeholder with
#      `mkpasswd -m sha-512` output before installing. Removed by C.
#   B  Secure boot. `sbctl create-keys` into the persisted /var/lib/sbctl,
#      enroll with the firmware in Setup Mode, then security.secureBoot.enable
#      = true. See docs/SECURE_BOOT_SETUP.md.
#   C  Secrets. Host age key to /persist/etc/sops-age-keys.txt, its public half
#      added as a recipient, /persist/etc/sops/secrets.yaml carrying
#      users/logger/password. Then add my.secrets (runtime paths ONLY --
#      my.secrets.allowSecretsInStore refuses store paths, because /nix/store is
#      world-readable and permanent) and delete GATE A's hash.
#   D  my.security.sshAgentSudo, once a YubiKey permanently lives in this box,
#      with its serial in residentSerials.
#   E  Radicle roles. Mint two ed25519 NIDs, declare
#      radicle-ads-dev1-{seed,x64-builder} in flake.nix, pass them here as
#      radicleGuests, and add the new seed's NID BESIDE yoga's in
#      users/logger -- a seed's identity is its key, so redundancy is a longer
#      connect list and never a shared name.
