{ mynixos
, claude-desktop ? null
, ...
}:

let
  # Decrypt a guest's key into the directory that guest reads it from. Written
  # to a temporary name and renamed, so a reader sees either the old file or the
  # new one and never a half-written key.
  #
  # THE ONE THING A GUEST CANNOT DO FOR ITSELF, which is why it is written on
  # this side: sops-install-secrets mounts a ramfs, needing a CAP_SYS_ADMIN a
  # rootless container has not got. So the key is decrypted HERE, by root, and
  # bind-mounted in already plaintext. Any ciphertext this host keeps beside it
  # is its own business, not the guest's.
  #
  # 0444 is deliberate rather than sloppy: a service inside reads its keystore
  # AFTER dropping privileges, and this host's guest account maps to container
  # ROOT, so a 0400 file owned by it is unreadable to the one process that needs
  # it. The directory above is 0711 and owned by an account nothing else uses,
  # so nothing on the host gains access.
  decryptKey = ''
    SOPS_AGE_KEY_FILE="$IDENTITY_DIR/age.key" \
      sops --decrypt --extract '["radicle"]["node-key"]' \
      "$IDENTITY_DIR/secrets.yaml" > "$IDENTITY_DIR/.node-key.new"
    chmod 0444 "$IDENTITY_DIR/.node-key.new"
    mv -f "$IDENTITY_DIR/.node-key.new" "$IDENTITY_DIR/node-key"
    chmod 0400 "$IDENTITY_DIR/age.key" "$IDENTITY_DIR/secrets.yaml"
  '';

  # THE MACHINES THIS HOST RUNS, BUILT WHERE THEY ARE RUN.
  #
  # These are machines in their own right -- each has a hostname, its own NID,
  # its own tailnet node, and knows nothing about what hosts it. What is yoga's
  # is only the decision to run them and what this machine will spend on them,
  # and that is stated in my.virtualisation.containers.guests below.
  #
  # They used to be `nixosConfigurations.radicle-yoga-*` in flake.nix, threaded
  # back in through a `radicleGuests` argument. That cost three things and
  # bought none: it forced a `self` reference for a value this file could import
  # directly; it put the guests in the one output that means "a host you can
  # install", where `nix flake check` dutifully tried to build a bootable
  # toplevel for a machine with no disk and failed; and it left this file
  # re-deriving every per-guest field with a `map` over the injected list --
  # reading each guest to decide what that guest gets. Written here, each value
  # is simply stated.
  #
  # `host = "yoga"` is the only literal: a tailnet name must be unique
  # FLEET-wide and tailscale does not reject a collision, it silently appends
  # -1. The guests derive radicle-yoga-{seed,x64-builder} from it, the
  # containers take their names from the guests, and the host-side accounts from
  # those.
  radicleSeed = import ../radicle-seed {
    inherit mynixos;
    host = "yoga";
    # Minted 2026-09-02. NOT disposable: every workstation pins this NID in a
    # `connect` entry, so rotating it means visiting each of them.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyY9GfELIEcnfz8bAlbPWp68FYgNGADDEPk9J29+3h5";
    identityDir = "/var/lib/radicle-seed-identity";
    # CI runs on the builder and the reports exist only there.
    ciReportsFrom = "http://radicle-yoga-x64-builder.tail46cce1.ts.net:8782/";
    avatarDefault = ../../users/logger/avatar.png;
    avatarsByEmail."i-am-logger@users.noreply.github.com" = ../../users/logger/avatar.png;
  };

  radicleBuilder = import ../radicle-builder {
    inherit mynixos;
    host = "yoga";
    # Minted 2026-09-01. Disposable by design -- a CI recipe can read it, which
    # is the accepted risk that makes a builder its own machine.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+Z/2uDBYlhSj6dsI4s7KqOcs0/HBxZX8rIBe/ROzDK";
    identityDir = "/var/lib/radicle-identity";
    connect = [
      "z6Mks9Ty1pdeM6LWsivN674EL3s3qCf8aVo8hw9KN3gmSPwW@radicle-yoga-seed.tail46cce1.ts.net:8776"
    ];
    reportsPublicUrl = "https://radicle-yoga-seed.tail46cce1.ts.net/ci";
  };
in

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

        # Local checkouts `test-system --local` / `build-system --local` build
        # from instead of the lock, when the path is on this machine; a switch
        # always builds from flake.lock. vogix is reached through mynixos, so it
        # needs the nested input path rather than a bare name.
        localInputs = {
          mynixos = "/home/logger/Code/logger/mynixos";
          "mynixos/vogix" = "/home/logger/Code/logger/vogix";
        };
        # kernel defaults to mynixos system module (linuxPackages_latest)
        # Override with: kernel = pkgs.linuxPackages_6_12; (or any other kernel package)
      };

      # Hardware configuration
      hardware = {
        # YubiKey device support (pcscd, udev, PAM, gnupg agent). Moved out of
        # my.security — it is device wiring, not policy.
        securityKeys.yubico.enable = true;
        # The cards that live in this machine: only theirs are offered to SSH,
        # so an absent card is never asked for, and the first is gpg's
        # default-key.
        securityKeys.residentSerials = [ "17027658" "15147050" ];

        # Dell AW3225QF, on HDMI through the Elgato 4K X. Without HDMI 2.1 FRL
        # the link tops out at 600 MHz TMDS, so `highres` lands on 4K@60 with
        # HDR (8 bpc on the wire). The panel's single DP input belongs to
        # ads-dev1. FRL (display.hdmiFrl.enable) is a separate, live-tested step.
        display.monitors.dell.aw3225qf.main = { };

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

        # Elgato Game Capture 4K X in this host's HDMI chain: it reports no
        # ELD, so the monitor's EDID is forced onto HDMI-A-1 and HDMI audio
        # pins stay up (moved here from the X870E board profile).
        peripherals.elgato.game-capture-4k-x = {
          enable = true;
          passthrough.output = "HDMI-A-1";
        };
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

        # Login: greetd+tuigreet (text). The vogix SDDM greeter is parked: its
        # teardown races the user session's modeset on this host's amdgpu
        # CRTC-disable path (chronic optc31_disable_crtc timeout) and freezes
        # the display most logins. Restore backend = "sddm" / look = "vogix"
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

        # Headless sudo: authenticate against the operator's forwarded SSH
        # agent, so the YubiKey answering for sudo is the one in the laptop at
        # the other end of the connection. pam_u2f stays for the local console.
        # Every key in yubikeys.nix authorizes sudo over SSH, the two that live
        # in this machine included (owner, 2026-11-15).
        sshAgentSudo.enable = true;
      };

      # Secrets management via sops-nix.
      #
      # NOTHING HERE MAY BE A STORE PATH -- not the age key, and not the
      # encrypted files it decrypts. /nix/store is world-readable and
      # permanent, so a secret placed there is published to every process on
      # this host and cannot be withdrawn.
      #
      # This used to read `"${secrets}/secrets.yaml"`, interpolating the
      # ~/.secrets flake input. That copies the whole DIRECTORY into the store,
      # not the one file named -- which is how the seed's plaintext node key,
      # an empty .enc and a stray root-owned `result` symlink all ended up
      # world-readable in two store paths, with nothing in this file naming
      # them. my.secrets.allowSecretsInStore now refuses that shape outright.
      #
      # These are runtime paths on /persist, populated out of band. Decryption
      # happens at activation with the host age key; the YubiKeys are used for
      # encryption only.
      secrets = {
        enable = true;
        defaultSopsFile = "/persist/etc/sops/secrets.yaml";
        ageKeyFile = "/persist/etc/sops-age-keys.txt";
      };

      # Infrastructure: System-level services and infrastructure
      # - containers: Rootless podman (auto-enabled by user dev feature)
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

      # Network: Tailscale SaaS. The self-hosted headscale + Tor onion design
      # that used to live here was retired without ever being bootstrapped
      # (zero nodes registered): the iPhone and iPad joined the tailscale.com
      # tailnet trivially, and the computers now follow them instead of making
      # every client as hard as the hardest one. The mynixos headscale/onion
      # modules remain for a future self-hosted migration.
      network = {
        tailscale = {
          enable = true; # controlPlane defaults to "tailscale" (SaaS)

          # Relay for the container roles this host runs. They are NATed
          # through this machine by rootless podman with no reachable UDP
          # endpoint, so they cannot form direct connections and were measured
          # relaying to each other through a DERP server in Denver at ~25ms --
          # two containers on this very box.
          #
          # INERT WITHOUT A TAILNET GRANT. Clients need
          # `tailscale.com/cap/relay` naming this host, and that lives in the
          # tailnet policy rather than in any Nix file while the fleet is on
          # Tailscale SaaS. Until it is added the port binds and every peer
          # stays on DERP.
          relayServerPort = 41647;
          # Inbound ssh over the tailnet is authenticated by tailnet identity
          # (tailnet policy `ssh` rules), so the iPad and the Mac need no key
          # material to reach this host. Classic sshd + YubiKey pubkeys stays
          # live on tailscale0 as the fallback path.
          ssh = true;
          # `tailscale serve` ports. serve binds a real kernel listener on the
          # tailnet IP, so peer traffic traverses the tailscale0 interface
          # firewall like anything else -- a serve config alone is not enough.
          allowedTCPPorts = [
            1989 # trunk dev server (praxis WASM surface), proxied via serve
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
      # WHAT THIS HOST RUNS INSIDE ITSELF, and what it will spend on each.
      #
      # The guests are built above; this is the only part that is genuinely
      # yoga's. Nothing here names a container: each is named by its own
      # my.system.hostname, so renaming a guest renames its container, its
      # host-side account and its state directory together.
      #
      # RESOURCE LIMITS ARE THE HOST'S, deliberately -- unlike a VM's
      # virtualisation.memorySize, which is virtual hardware the guest genuinely
      # has and wants wherever it runs. A container's limit is a cgroup ceiling
      # this machine imposes to defend itself, so a guest cannot raise it.
      virtualisation.containers.guests = [
        {
          system = radicleSeed;
          identityScript = decryptKey;
          identityDir = "/var/lib/radicle-seed-identity";

          # PINNED TO WHAT IS ALREADY ON DISK, and transitional. The defaults
          # would both be right for a new fleet -- the account derives from the
          # guest as "<hostname>-user" and the state directory from the same --
          # but neither matches what is RUNNING, and changing either migrates
          # nothing: podman would mount a new empty directory, so the node would
          # come up holding no repositories and, worse, no tailscale
          # registration, which cannot be repaired without an auth key and a
          # hand-run `tailscale up`. The rename lands as its own change, with
          # the state moved deliberately, rather than as a refactor's side
          # effect.
          user = "radicle-seed-forge";
          stateDir = "/var/lib/radicle-roles/radicle-yoga-seed";

          stateVolumes = {
            radicle = "/var/lib/radicle";
            tailscale = "/var/lib/tailscale";
          };
          # memory and pidsLimit left at their defaults (4g / 2048): a seed
          # runs no untrusted code.
        }

        {
          system = radicleBuilder;
          identityScript = decryptKey;
          identityDir = "/var/lib/radicle-identity";
          user = "radicle-forge"; # as above: pinned to what is on disk
          stateDir = "/var/lib/radicle-roles/radicle-yoga-x64-builder";

          stateVolumes = {
            radicle = "/var/lib/radicle";
            tailscale = "/var/lib/tailscale";
            radicle-ci = "/var/lib/radicle-ci";
          };

          # A CI recipe can fork-bomb or exhaust memory, and nothing else
          # addresses denial of service against this machine.
          memory = "16g";
          pidsLimit = 4096;

          # A builder BUILDS, and nix builds in a sandbox -- which needs /proc
          # fully visible, not a capability. See the option for why the error it
          # fixes reads as a missing capability and is not one.
          nixSandbox = true;
        }
      ];

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

      # The Lua config engine, mynixos's default since 0.28 and the only one
      # Hyprland ≥0.57 accepts; stated here as the host's own fact.
      users.logger.apps.graphical.windowManagers.hyprland.configType = "lua";
    }

  ];

  # THE FORGE IS NOT PART OF THIS HOST. yoga runs no radicle service of its own:
  # it HOSTS two container roles, each its own machine with its own NID and its
  # own tailnet node, and knows nothing about what they do. There used to be a
  # ./radicle.nix here configuring a seed, httpd, explorer, CI and mirror
  # directly on this host; the seed was the last of those to move, and the file
  # went with it. Rollback is `git revert`, not a flag.
  extraModules = [
    # DDR5 modules on this build carry addressable RGB (ENE controllers). DRAM RGB
    # is its own hardware -- it travels with the sticks, independent of the board
    # and the keyboard -- and is driven by OpenRGB, which lives in vogix. So flip
    # vogix's dram-rgb hardware module on directly (it pulls in OpenRGB + the
    # chipset SMBus stack on its own). The OpenRGB build is vogix's too: vogix
    # pins it and asserts the readiness openrgb.service relies on.
    { vogix.hardware.dram-rgb.enable = true; }

    # btrfs checksums every extent but only VERIFIES a checksum when the extent
    # is read or scrubbed. Without a scrub, rot is discovered the day you open
    # the file -- which is the day it is already too late. Both btrfs
    # filesystems are named: they are separate partitions on this host, so
    # scrubbing one does not touch the other.
    {
      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/nix" "/persist" ];
      };
    }

    # yoga's own packages: claude-desktop, and this flake's claude-code and
    # herdr in place of nixpkgs'. Nothing fails without this module; yoga
    # silently falls back to nixpkgs' builds.
    (_: {
      # claude-desktop is passed as null by flake.nix until upstream stops
      # depending on the removed nodePackages.asar, so this list is empty in
      # practice -- the conditional is what survives the day it is non-null.
      environment.systemPackages =
        if claude-desktop != null then
          [ claude-desktop.packages.x86_64-linux.claude-desktop-with-fhs ]
        else
          [ ];

      nixpkgs.overlays = [
        (import ../../overlays/claude-code.nix)
        (import ../../overlays/herdr.nix)
      ];
    })

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
    # Login must never brick: greetd is the default; this boot entry brings
    # the vogix SDDM greeter back for testing the amdgpu CRTC handoff race.
    # Make it the default again once that race is fixed.
    ({ lib, ... }: {
      # mkForce: a specialisation merges with the base config, and the base
      # now pins greetd/stock at normal priority.
      specialisation.login-vogix.configuration = {
        my.environment.login = {
          backend = lib.mkForce "sddm";
          look = lib.mkForce "vogix";
        };
      };
    })

    # The unpatched kernel stays the default; select the "amdgpu-vm-tlb-test"
    # entry at the bootloader to run the patched kernel. Remove once validated.
    # TEMPORARILY DISABLED: building this specialisation builds linux-7.1.0 from
    # the local yoga-kernel branch, which is a from-source kernel compile on every
    # rebuild that touches it. Re-enable by deleting this comment and the /* */,
    # and adding `yoga-kernel` back to this file's arguments: flake.nix passes it,
    # and `...` accepts it while nothing here reads it.
    /*
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
    */
  ];
}
