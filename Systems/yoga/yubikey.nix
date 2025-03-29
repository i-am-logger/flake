{ config, pkgs, ... }:
{
  # Enable smartcard/CCID support
  services.pcscd.enable = true;
  # YubiKey personalization tool and udev rules
  services.udev.packages = [ pkgs.yubikey-personalization ];
  # Enable GPG smartcards support
  hardware.gpgSmartcards.enable = true;

  # Required packages for YubiKey functionality
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    yubikey-agent
    pam_u2f
    yubico-pam
    pcsc-tools
  ];

  # Enable PAM authentication with YubiKey
  security.pam = {
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true; # Enable U2F for sudo
      # Enable for display manager (GDM) as well
      gdm.u2fAuth = true;
    };
    u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        authfile = "/persist/yubikey/authorized_yubikeys";
        cue = true; # Provide visual feedback when waiting for a token
        interactive = true;
      };
    };
  };
  # Ensure YubiKey configurations persist across reboots
  environment.persistence."/persist" = {
    directories = [
      "/persist/yubikey"
    ];
    files = [
    ];
    users.logger = {
      directories = [
        ".yubico"  # YubiKey challenge-response files
      ];
    };
  };

  # Add user to required groups
  users.users.logger.extraGroups = [ "plugdev" ];

  # Disable system SSH agent in favor of GPG agent
  programs.ssh.startAgent = false;
}
