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
    gnome-keyring
    libgnome-keyring
    seahorse # GNOME's keyring manager GUI
  ];

  # Enable GNOME keyring
  services.gnome.gnome-keyring.enable = true;
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
        # Enable GNOME keyring unlock on login
        enableGnomeKeyring = true;
      };
      login.enableGnomeKeyring = true;
    };
    u2f = {
      enable = true;
      control = "sufficient";
      settings = {
        authfile = "/home/logger/.yubico/authorized_yubikeys";
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
  };

  # Disable system SSH agent
  programs.ssh.startAgent = false;

  # For GNOME keyring integration
  services.accounts-daemon.enable = true;

  # Enable dconf (required for saving GNOME keyring settings)
  programs.dconf.enable = true;

  # D-Bus activation for gnome-keyring
  services.dbus.packages = [ pkgs.gnome-keyring ];

  # Additional GNOME services that improve keyring integration
  services.gnome.glib-networking.enable = true;
  services.gnome.gnome-online-accounts.enable = true;

  # Create config file to set GPG as the primary backend for keyring
  environment.etc."xdg/autostart/gnome-keyring-gpg.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=GPG Password Agent
    Comment=GNOME Keyring: GPG Agent
    Exec=${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=gpg
    OnlyShowIn=GNOME;Unity;MATE;
    X-GNOME-Autostart-Phase=PreDisplayServer
    X-GNOME-AutoRestart=false
    X-GNOME-Autostart-Notify=true
  '';
}
