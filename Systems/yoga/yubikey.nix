{ config, pkgs, ... }:
{
  # Enable smartcard/CCID support
  services.pcscd.enable = true;

  # YubiKey personalization tool and udev rules
  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host # Add U2F host library for better support
  ];

  # Enable GPG smartcards support
  hardware.gpgSmartcards.enable = true;

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
  # Enable USB security key support (including YubiKey)
  # hardware.u2f.enable = true;

  # Required packages for YubiKey functionality
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    # Remove yubikey-agent as it conflicts with gpg-agent's SSH support
    # yubikey-agent
    pam_u2f
    yubico-pam
    pcsc-tools
    gnupg # Ensure system-level gpg is available
  ];

  # Create a systemd service to ensure pcscd is properly initialized
  systemd.services.pcscd-init = {
    description = "Initialize PCSCD for YubiKey";
    wantedBy = [ "multi-user.target" ];
    after = [ "pcscd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/sleep 2"; # Give pcscd time to initialize
      RemainAfterExit = true;
    };
  };

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

  # Create the persistence directories if they don't exist
  system.activationScripts.yubikey-dirs = ''
    mkdir -p /persist/yubikey
    chmod 755 /persist/yubikey
    if [ ! -e /persist/yubikey/authorized_yubikeys ]; then
      touch /persist/yubikey/authorized_yubikeys
      chmod 644 /persist/yubikey/authorized_yubikeys
    fi
  '';

  # Add user to required groups
  users.users.logger.extraGroups = [
    "plugdev"
    "pcscd"
  ];

  # Disable system SSH agent in favor of GPG agent
  programs.ssh.startAgent = false;

  # Add a hook to ensure gpg-agent is properly configured for SSH
  environment.shellInit = ''
    if [ -z "$SSH_AUTH_SOCK" ]; then
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    fi
  '';
}
