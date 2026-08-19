# aether5d-dev — Apple M5 Max MacBook Pro, macOS 27.0, aarch64-darwin.
#
# Reads the same way as systems/yoga and systems/skyspy-dev: one mkSystem call,
# `platform = "darwin"`, a hardware profile, and personal data under `my`.
# Everything generic lives in mynixos — the module set in mynixos/platforms/,
# the Apple hardware in my/hardware/laptops/apple/macbook-pro-m5-max, Touch ID in
# my/hardware/biometrics/apple.
{ mynixos }:

mynixos.lib.mkSystem {
  platform = "darwin";
  hostname = "aether5d-dev";

  my = {
    # Sets nixpkgs.hostPlatform, Touch ID and the CoreAudio sample-rate agent —
    # the same way yoga enables its motherboard profile. The module itself is
    # already in mynixos/platforms/darwin.nix, so like yoga this only flips the
    # option; the `hardware = [ ... ]` parameter is for out-of-tree profiles.
    hardware.laptops.apple.macbook-pro-m5-max = {
      enable = true;
      # macOS has no declarative mechanism for CoreAudio sample rates; the
      # profile drives the API from a launchd agent at login. See the module for
      # why "higher" is not automatically "better".
      audio.maxSampleRate = true;
    };

    system = {
      enable = true;

      # This host's flake is not at /etc/nixos or ~/.flake, so rebuild-system /
      # test-system / build-system need to be told where to look.
      flakeDir = "/Users/logger/Code/flake";

      # This machine is where the DSL is developed, so the rebuild scripts build
      # from the working tree when one is present rather than from flake.lock.
      # Each path is tested when the script runs, so nothing here breaks a host
      # that has no such checkout -- vogix is listed before it has been cloned
      # for exactly that reason, and starts taking effect the day it is.
      #
      # vogix is not a direct input of this flake, it is one of mynixos's, hence
      # the slash. Attribute order puts "mynixos" before "mynixos/vogix", which
      # is the order nix needs the overrides in.
      localInputs = {
        mynixos = "/Users/logger/Code/mynixos";
        "mynixos/vogix" = "/Users/logger/Code/vogix";
      };
    };

    # nix-darwin ASSERTS `nix.gc.automatic requires nix.enable`, and nix.enable
    # is false here (see extraModules), so its GC is unavailable. my/system/nix-gc
    # does the same job with plain launchd daemons, which have no such gating.
    nixGc.enable = true;

    # Remote Login, reachable ONLY over Tailscale. sshd_config's ListenAddress
    # does nothing on macOS because launchd owns the socket, so pf is what
    # actually scopes it.
    network.sshFirewall = {
      enable = true;
      # null = accept anything from the tailnet, relying on the control server's
      # ACLs. Restricting to [ 22 ] also blocked Tailscale's peerapi (it listens
      # on a random high port, so it cannot be enumerated), which breaks Taildrop
      # and peer node communication.
      tailnetPorts = null;
    };

    # Homebrew earns its keep for Mac App Store apps, which Nix cannot fetch
    # (Apple-ID-bound, DRM'd). No cask is named here any more: Discord's comes
    # from mynixos's own app module, which declares the cask on darwin and the
    # nixpkgs derivation on Linux, so the choice travels with the app rather
    # than with this host.
    #
    # See the homebrew activation override in extraModules: `brew bundle` reports
    # these masApps as failed even when they are installed and a direct
    # `mas install` exits 0, and the activation script's `set -e` turns that into
    # an aborted switch. The override keeps the declaration authoritative without
    # letting a false Homebrew failure cost the rest of activation.
    homebrew = {
      enable = true;
      user = "logger";
      # Background Music was here as a cava audio source. It is gone because
      # nothing needs it: mynixos's cava takes CoreAudio's own process tap
      # (`method = "coreaudio"; source = "tap"`), which is why cava's module
      # documents BGM only as a fallback for macOS < 14.2.
      #
      # homebrew.onActivation.cleanup is "uninstall", so the next switch removes
      # the cask, the HAL plugin and the _BGMXPCHelper service account.

      masApps = {
        # The App Store build, kept deliberately: it uses Apple's
        # NetworkExtension, which the open-source tailscaled does not.
        "Tailscale" = 1475387142;
        "1Password for Safari" = 1569813296;
        # The App Store record really is named "Fidelia.app", hence the doubled
        # extension on disk — upstream's doing, not a botched install.
        "Fidelia.app" = 416135376;
      };
    };

    # Personal user data, shared verbatim with yoga and skyspy-dev. Its `darwin`
    # tier supplies what applies only here, and mkSystem drops the `linux` tier —
    # the sops password hash, the AccountsService avatar, libinput's accelSpeed,
    # OBS and the media apps.
    #
    # NOT set here: graphical.enable, which my/users/graphical/mynixos-darwin.nix forces
    # true because macOS cannot not be graphical. Hyprland, walker and waybar do
    # not follow from it — those modules are absent from platforms/darwin.nix.
    users = import ../../users;
  };

  extraModules = [
    ./macos-defaults.nix

    ({ config, lib, ... }: {
      # Asserted, not defaulted. 7 is system.maxStateVersion at the pinned
      # nix-darwin rev. Set once, never changed without reading the changelog.
      system.stateVersion = 7;

      # All activation runs as root since nix-darwin's 2025-01-30 change; options
      # that used to apply to whoever ran darwin-rebuild now apply to this user.
      # Required by every user-scoped system.defaults.* write.
      system.primaryUser = "logger";

      # -----------------------------------------------------------------------
      # Two overlays, both temporary, both here because the nixpkgs pin trails
      # upstream on something this machine runs all day.
      #
      # claude-code: overlays/claude-code.nix hands the same nixpkgs derivation
      # a newer release manifest. Upstream publishes a checksum per platform,
      # so the one overlay covers this host and the two NixOS ones, and all
      # three land on the same version. Regenerate with
      # scripts/update-claude-code.sh; that file says how to wind it down.
      #
      # wezterm comes from the kitty image branch, not the pin.
      #
      # Two things the pin gets wrong on this machine. The kitty `t=s` shared
      # memory transport never draws: a POSIX shared memory object can only be
      # mapped on Darwin, and the arm reads it with seek/read_exact, so every
      # `t=s` image is dropped with ENXIO and no reply to the application. And
      # every image is hashed three times in software, which is most of a frame
      # budget for anything streaming pixels.
      #
      # Sent upstream as wezterm/wezterm#8061. Drop that import and
      # overlays/wezterm-kitty-pr.nix once it lands and the pin moves past it.
      # It replaces src and re-vendors cargoDeps, nothing else.
      nixpkgs.overlays = [
        (import ../../overlays/claude-code.nix)
        (import ../../overlays/herdr.nix)
        (import ../../overlays/wezterm-kitty-pr.nix)
      ];

      # -----------------------------------------------------------------------
      # Homebrew must not be able to abort activation.
      #
      # nix-darwin runs `brew bundle` from the activation script as
      #   sudo --preserve-env=PATH --user=logger --set-home env brew bundle ...
      # and the script runs under `set -e`. `brew bundle` reports every masApps
      # entry as "Installing X has failed!" even when the app IS installed --
      # verified: `mas list` shows all three, and `mas install <id>` exits 0 for
      # each, from both the Nix mas and Homebrew's. Only the invocation through
      # `sudo --user` disagrees.
      #
      # The consequence is out of all proportion to the cause: the non-zero exit
      # ends activation at this line, and home-manager activates on the NEXT
      # line. A cosmetic App Store complaint therefore silently costs the entire
      # per-user configuration -- no ~/.zshrc, no home-manager profile.
      #
      # So the bundle step reports and continues. Homebrew here manages three
      # App Store apps and one cask; none of them is load-bearing enough to be
      # worth failing a system switch over, and a real failure is still printed.
      system.activationScripts.homebrew.text = lib.mkForce ''
        echo >&2 "Homebrew bundle..."
        if [ -f "${config.homebrew.prefix or "/opt/homebrew"}/bin/brew" ]; then
          ${config.homebrew.onActivation.brewBundleCmd { onlyCheck = false; }} || \
            echo >&2 "warning: brew bundle reported a failure; continuing activation"
        else
          echo >&2 "warning: Homebrew is not installed, skipping bundle"
        fi
      '';

      # -----------------------------------------------------------------------
      # Nix itself stays OUT of nix-darwin's hands.
      #
      # This machine runs Nix 2.35.1 from the NixOS nix-installer. Handing the
      # daemon to nix-darwin would:
      #   * regenerate /etc/nix/nix.conf from nix.settings, which does NOT
      #     include experimental-features by default. darwin-rebuild passes
      #     `--extra-experimental-features 'nix-command flakes'` to itself, so
      #     rebuilds would keep working while `nix build`, `nix develop`,
      #     `nix run`, direnv and devenv all broke — the worst failure mode.
      #   * downgrade the daemon: pkgs.nix here is 2.34.8, we run 2.35.1.
      #   * fight systems.determinate.nix-installer.nix-hook.plist, which runs
      #     `nix-installer repair` at every boot.
      #
      # Keeping it false also means `darwin-uninstaller` leaves the Nix
      # installation completely intact.
      # -----------------------------------------------------------------------
      nix.enable = false;

      # macOS Application Firewall. Ships OFF on macOS; this is a deliberate
      # change from stock, not a capture of current state.
      #
      # It is NOT what restricts SSH — ALF filters per-application, not per
      # interface or port, and sshd is Apple-signed so allowSigned lets it accept
      # connections on every interface. my.network.sshFirewall (pf) does that
      # job. ALF is the complementary layer: it catches anything ELSE that starts
      # listening and stops it silently accepting connections off the LAN.
      networking.applicationFirewall = {
        enable = true;

        # false on purpose: blockAllIncoming blocks every incoming connection
        # including sshd, on all interfaces, defeating Mac <-> yoga SSH.
        blockAllIncoming = false;

        # Both true, matching current machine state, so nothing that works today
        # breaks. allowSignedApp is the loose one — any Developer-ID-signed app is
        # auto-allowed. Set it false for per-app approval prompts instead.
        allowSigned = true;
        allowSignedApp = true;

        # Stop replying to ICMP echo and probes to closed ports. Tailscale's own
        # connectivity checks do not use ICMP so the tailnet is unaffected, but
        # plain `ping` to this Mac will no longer answer.
        enableStealthMode = true;
      };

      # nix-darwin enables sshd via `launchctl bootstrap system/com.openssh.sshd`
      # rather than `systemsetup -setremotelogin`, which would need Full Disk
      # Access.
      services.openssh.enable = true;

      # NOTE: ~/Library/Fonts still holds hand-copied FiraCode Nerd Font TTFs.
      # Delete those on the first switch, or the family is duplicated -- fonts now
      # come from my.fonts (mynixos), which nix-darwin rsyncs into
      # "/Library/Fonts/Nix Fonts".


      # System timezone — was unmanaged; captured from /etc/localtime.
      time.timeZone = "America/Denver";

      # Net for ~/.zshrc, ~/.gitconfig and ~/.config/cava/config, which
      # home-manager will otherwise refuse to overwrite. mkSystem's default is
      # "backup"; this names it for what it is on a first takeover. Note it is
      # not idempotent across repeated conflicts — move the originals aside by
      # hand rather than relying on it.
      home-manager.backupFileExtension = lib.mkForce "before-nix-darwin";

      # Host-specific home-manager bits (Secretive agent, fd/ripgrep/zoxide/fzf).
      home-manager.users.logger = import ./home.nix;
    })
  ];
}
