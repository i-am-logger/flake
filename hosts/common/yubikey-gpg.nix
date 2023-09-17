{pkgs, ...}: {
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
    yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubioath-flutter
    yubico-pam
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
    enableSSHSupport = true;
  };

  # Enable smart card mode
  services.pcscd.enable = true;

  # Enable the u2f PAM module for login and sudo requests
  security.pam = {
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };

    yubico = {
      enable = true;
      debug = true;
      mode = "challenge-response";
      id = ["17027658"];
    };
  };
}
