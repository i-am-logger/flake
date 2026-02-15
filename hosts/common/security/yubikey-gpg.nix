{ pkgs, ... }:
let
  # Import YubiKey constants
  constants = import ../../../home/logger/yubikey-constants.nix;
in
{
  # Enable smartcard support properly
  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
    age
    # Tools for backing up keys
    paperkey
    pgpdump
    parted
    cryptsetup

    # Yubico's tools
    yubikey-manager
    yubioath-flutter
    yubikey-personalization
    yubico-piv-tool
    yubico-pam
    pcsc-tools
    pcsclite
    yubikey-agent
  ];
  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  programs.gnupg.agent = {
    enable = true;
    # pinentryFlavor = "curses";
    enableSSHSupport = true;
  };

  # Disable system SSH agent in favor of GPG agent
  programs.ssh.startAgent = false;

  # Enable the u2f PAM module for login and sudo requests
  security.pam = {
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      gdm.u2fAuth = true;
    };

    u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        cue = true;
        interactive = true;
      };
    };

    yubico = {
      enable = true;
      debug = false;
      mode = "challenge-response";
      id = [ constants.yubikey1Serial constants.yubikey2Serial ];
    };
  };

  # Ensure user is in the required groups
  users.users.logger.extraGroups = [ "plugdev" ];
}
