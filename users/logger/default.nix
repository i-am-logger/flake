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

  # Read for its length by apps/ssh: a non-empty list sets IdentitiesOnly=no, so
  # ssh offers agent-held keys to github.com. That is why it stays shared even
  # though the Mac signs with a Secure Enclave key via Secretive rather than a
  # YubiKey.
  yubikeys = import ./yubikeys.nix;

  graphical.enable = true;
  terminal = {
    enable = true;
    multiplexer = "zellij";
  };
  dev = {
    enable = true;
    docker.enable = true;
  };
  ai.enable = true;

  # Handedness is the person, not the machine. Pointer acceleration is not:
  # libinput's scale and com.apple.mouse.scaling have no common ground, so it
  # sits in the linux tier below.
  input.leftHanded = true;

  apps = {
    security.passwords.onePassword.enable = true;
    ai.tools.claude-code.cloneConfigRepo = "git@github.com:i-am-logger/claude-config.git";
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
  };
}
