{ pkgs, ... }:
{
  # Core YubiKey services
  services.pcscd.enable = true;
  services.yubikey-agent.enable = false; # Explicitly disable in favor of gpg-agent
  hardware.gpgSmartcards.enable = true;

  # YubiKey-related packages and support
  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host
  ];

  # Persistence configuration (this is good as is)
  environment.persistence."/persist" = {
    directories = [ "/persist/yubikey" ];
    users.logger = {
      directories = [
        ".gnupg"
        ".yubico"
        ".ssh"
      ];
    };
  };

  # Essential packages only
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    pcsc-tools
    # Let home-manager handle gnupg
  ];

  # PAM authentication configuration (this is good as is)
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
        authfile = "/persist/yubikey/authorized_yubikeys";
        cue = true;
        interactive = true;
      };
    };
  };

  # Required user groups
  users.users.logger.extraGroups = [
    "plugdev"
    "pcscd"
  ];

  # Disable system SSH agent
  programs.ssh.startAgent = false;
}
