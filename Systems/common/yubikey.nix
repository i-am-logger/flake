{ pkgs, ... }:
{
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

  services.udev.packages = [
    pkgs.yubikey-personalization
    pkgs.libu2f-host
  ];

  environment.systemPackages = with pkgs; [
    pinentry-gnome3
    # gnome-keyring removed - not needed when keyring is disabled
    # libgnome-keyring removed - not needed when keyring is disabled
    # seahorse removed - GNOME keyring manager not needed
  ];

  # Completely disable GNOME keyring to prevent authentication prompts
  # Applications like Warp will not try to access the keyring
  services.gnome.gnome-keyring.enable = false;
  security.polkit.enable = true;

  # Configure GPG agent for proper GNOME integration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  # Note: skyspy-dev now uses impermanence, so we store yubikey data in /persist
  # This will be handled by the persistence.nix configuration

  security.pam = {
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
      gdm = {
        u2fAuth = true;
        # Disable GNOME keyring unlock to prevent login keyring authentication prompts
        enableGnomeKeyring = false;
      };
      login.enableGnomeKeyring = false;
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
    # Ensure proper GPG TTY setting
    GPG_TTY = "$(tty)";
    # Disable GNOME Keyring SSH agent to prevent conflicts
    GNOME_KEYRING_CONTROL = "";
    # Force applications to use gpg-agent for authentication
    DISABLE_GNOME_KEYRING = "1";
  };

  # Disable system SSH agent
  programs.ssh.startAgent = false;

  # GNOME keyring integration disabled - using gpg-agent for all authentication
  # services.accounts-daemon.enable = true; # Not needed without keyring

  # Enable dconf for other GNOME applications (not keyring-specific)
  programs.dconf.enable = true;

  # D-Bus packages for keyring removed
  # services.dbus.packages = [ pkgs.gnome-keyring ]; # Not needed

  # Keep essential GNOME services that don't depend on keyring
  services.gnome.glib-networking.enable = true;
  # services.gnome.gnome-online-accounts.enable = false; # Disabled - depends on keyring
}
