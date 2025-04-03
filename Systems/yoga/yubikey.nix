{ pkgs, ... }:
{
  # Core YubiKey services
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  systemd.services.pcscd = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  services.yubikey-agent.enable = false; # Explicitly disable in favor of gpg-agent
  hardware.gpgSmartcards.enable = true;

  # services.udev.extraRules = ''
  #   # YubiKey rules to allow both pcscd and direct access
  #   ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", TAG+="systemd", ENV{SYSTEMD_WANTS}="pcscd.service", GROUP="users", MODE="0660"
  # '';
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
  # environment.systemPackages = with pkgs; [
  #   # yubikey-manager
  #   # yubikey-personalization
  #   # pcsc-tools
  # ];

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

  environment.sessionVariables = {
    # This ensures SSH knows to use the GPG agent
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };

  # Disable system SSH agent
  programs.ssh.startAgent = false;
}
