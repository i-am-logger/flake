# User configuration for: logger (Ido Samuelson)
#
# Plain Nix data, shared verbatim by every host. No `lib`, so there is no
# mkDefault here: everything stated is a hard definition, and anything mynixos
# already defaults is left unsaid rather than restated.
#
# `linux` and `darwin` are reserved keys holding values that apply on that
# platform alone; mkSystem strips them before the module system sees anything,
# so `my.users.logger.linux` never becomes an option path. Put a fact in a tier
# only when the answer genuinely differs by platform — if the answer is
# "whatever this platform normally does", it belongs to a mynixos default, not
# here.
{
  fullName = "Ido Samuelson";
  description = "whistleblower";
  email = "i-am-logger@users.noreply.github.com";

  github.username = "i-am-logger";

  # Read for its length by apps/ssh: a non-empty list sets IdentitiesOnly=no so
  # ssh offers agent-held keys to the forges, and suppresses ControlMaster
  # multiplexing, whose sockets fight with an external agent. The Mac reaches
  # github over https now (see the darwin tier), so the first half is inert
  # there — the second is not, and Secretive is an external agent too, so the
  # list stays shared.
  yubikeys = import ./yubikeys.nix;

  graphical.enable = true;
  terminal = {
    enable = true;
    # Same value mynixos now defaults to, said out loud anyway: this file's
    # header calls everything here a hard definition, and which multiplexer the
    # day happens in is worth reading off the page rather than inferring.
    multiplexer = "herdr";
  };
  dev = {
    enable = true;
    containers.enable = true;
  };
  ai.enable = true;

  # Handedness is the person, not the machine. Pointer acceleration is not:
  # libinput's scale and com.apple.mouse.scaling have no common ground, so it
  # sits in the linux tier below.
  input.leftHanded = true;

  apps = {
    security.passwords.onePassword.enable = true;

    # yoga alone, because forwarding hands the far end a socket that signs with
    # this machine's key. yoga sets my.security.sshAgentSudo, so sudo there is
    # answered by the YubiKey at THIS end and the server needs no key of its own.
    terminal.network.ssh.forwardAgentHosts = [ "yoga" ];

    # Radicle CLI (rad, git-remote-rad) on every machine, the Mac included —
    # the identity lives in ~/.radicle (persisted by the app option). The
    # per-user daemon is Linux-only and sits in the linux tier below.
    dev.tools.radicle = {
      enable = true;
      # The web explorer is a PUBLIC gateway -- it 404s private repos, and
      # most of ours are private. These read the local node directly, so they
      # are what actually browses a private repo.
      tui = true;
      desktop = true;
      job = true; # rad-job: the only way to read CI results
    };

    # Cross-repo tooling: the babysitter CLI is a Claude Code plugin
    # dependency, so it belongs in the profile rather than in any one repo's
    # dev shell -- that is what makes it work from every checkout.
    ai.tools.babysitter.enable = true;

    # Written https:// rather than git@ on purpose: apps.dev.tools.git.protocol
    # is what decides the transport, and an ssh:// literal would bypass it and
    # fail on any host without a forge-accepted SSH key. The ssh hosts rewrite
    # it back through insteadOf.
    ai.tools.claude-code = {
      cloneConfigRepo = "https://github.com/i-am-logger/claude-config.git";

      # One Claude.ai login per account; ~/Code/cosmic is Cosmic Clarity
      # Connection work and runs on its own subscription. Everything else
      # falls through to the default.
      defaultAccount = "gmail";
      accounts = {
        gmail = { email = "ido.samuelson@gmail.com"; };
        hotmail = { email = "ido.samuelson@hotmail.com"; };
        bootstrapper = {
          email = "ibootstrapper@gmail.com";
          directories = [ "~/Code/cosmic" ];
        };
      };
    };
  };

  # Folders that are mine rather than any program's, kept across a wipe on the
  # impermanence hosts. Software state is declared by the software's own module,
  # so nothing app-related belongs here.
  persistedDirectories = [
    "Code"
    "Media"
  ];

  linux = {
    # sops-nix writes the hash to a file and NixOS reads it at account creation.
    # macOS accounts are made by Setup Assistant, and nix-darwin only touches an
    # account listed in users.knownUsers, which mynixos deliberately leaves alone.
    secrets.hashedPassword = true;

    # Consumed by AccountsService for the greeter. macOS stores the account
    # picture in the local directory service, with no declarative interface.
    avatar = ./avatar.png;

    input.accelSpeed = -0.3; # libinput scale: 0.0 is the device default, not "off"
    input.keyboardLayouts = [ "us" "il" ]; # EN/HE — the HUD's kbd chip cycles these

    # Upstream marks rustdesk badPlatforms = [ "aarch64-darwin" ], so it cannot
    # sit in the shared profile: aether5d-dev refuses to evaluate at all.
    apps.graphical.network.rustdesk.enable = true;

    # Radicle user node: outbound-only daemon dialing the fleet's seeds.
    # Dormant until `rad auth` has run on the machine (ConditionPathExists on
    # the key), so this is safe on a host that has not been bootstrapped yet.
    # Enabling it also pins ~/.radicle/config.json to the private-net shape --
    # `rad auth` writes the PUBLIC iris/rosa seeds into preferredSeeds, which
    # is exactly what must not survive here. Turn on with GATE A.
    apps.dev.tools.radicle.node = {
      enable = true;
      # TWO seeds, both dialed, and that is what P2P redundancy means here: an
      # entry per seed, never one address in front of a pair. Each seed's
      # identity is its NID, which lives in the KEY rather than the host, so
      # they cannot be collapsed behind a shared name -- a client that dialed
      # one NID and reached the other would fail the Noise XK handshake, since
      # it pins the responder key.
      #
      # First the original host seed, then the container seed standing beside
      # it. Both are live and neither is a fallback for the other. Deleting
      # the first belongs to retiring it, which is a separate decision from
      # adding the second -- that separation is the whole reason there is no
      # destructive step in standing this one up.
      connect = [
        "z6MkqSoohjxUYVfQRqFxCKeRGSJeE8D5dTxkBe8neHWt6Rb1@yoga.tail46cce1.ts.net:8776"
        "z6Mks9Ty1pdeM6LWsivN674EL3s3qCf8aVo8hw9KN3gmSPwW@radicle-yoga-seed.tail46cce1.ts.net:8776"
      ];
    };

    graphical = {
      streaming.enable = true; # OBS
      media.enable = true; # gimp, krita, inkscape, mypaint
    };
  };

  darwin = {

    # Menu-bar sleep toggle, packaged in mynixos rather than taken from a
    # Homebrew cask. `caffeinate -di` does the same job from the CLI; this one is
    # visible at a glance.
    apps.graphical.utils.keepingyouawake.enable = true;

    # A credential fact, not a platform one — it sits here because THIS Mac has
    # no SSH identity github accepts (Secretive is installed but its Secure
    # Enclave key was never created), while `gh` holds a token in the keyring.
    # Provision that key and this line comes back out.
    apps.dev.tools.git.protocol = "https";

    # In the darwin tier only because that is where Discord is actually wanted,
    # not because the app is one-sided: mynixos declares the option on both
    # platforms and implements it per-platform (nixpkgs derivation on Linux, a
    # Homebrew cask here). Move this line up a level to get it on yoga and
    # skyspy-dev too.
    apps.communication.messaging.discord.enable = true;
  };
}
