{ config, pkgs, ... }:
{
  # Enable smartcard/CCID support
  services.pcscd.enable = true;

  # YubiKey personalization tool and udev rules
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Required packages for YubiKey functionality
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    yubikey-agent
    pam_u2f
    yubico-pam
    # GPG related packages
    gnupg
    pinentry
    paperkey
    pinentry-curses
  ];

  # Enable PAM authentication with YubiKey
  security.pam = {
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = false;  # Explicitly disable U2F for sudo
      # Enable for display manager (GDM) as well
      gdm.u2fAuth = true;
    };
    u2f = {
      enable = true;
      control = "required";
      settings = {
        authfile = "/persist/yubikey/authorized_yubikeys";
        cue = true;  # Provide visual feedback when waiting for a token
      };
    };
  };
  # Ensure YubiKey configurations persist across reboots
  environment.persistence."/persist" = {
    directories = [
      "/persist/yubikey"
    ];
    files = [
      "/etc/nixos/.gnupg/gpg.conf"
      "/etc/nixos/.gnupg/gpg-agent.conf"
    ];
    users.logger = {
      directories = [
        ".gnupg"
        ".yubico"   # YubiKey challenge-response files
      ];
    };
  };

  # Add user to required groups
  users.users.logger.extraGroups = [ "plugdev" ];

  # SSH support for YubiKey
  programs.ssh.startAgent = false;  # Disable default SSH agent
  services.yubikey-agent.enable = true;  # Enable YubiKey agent for SSH

  # GPG agent configuration
  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;  # Use GPG agent for SSH
      # pinentryFlavor = "curses";  # Use the curses-based dialog
    };
  };

  # For compatibility with more applications
  environment.shellInit = ''
    export GPG_TTY=$(tty)
    gpg-connect-agent updatestartuptty /bye > /dev/null
  '';
}
