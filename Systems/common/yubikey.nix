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
    pass # GPG-based password manager
    pass-secret-service # Bridge pass to Secret Service API for apps like Element
    libsecret # Required for Electron apps to use Secret Service
    libfido2 # Provide FIDO2 provider for OpenSSH sk keys
  ];

  # Disable GNOME keyring - using pass with GPG/YubiKey instead
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
        # Disable GNOME keyring - using pass with GPG/YubiKey
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
    # Disable GNOME Keyring completely - using pass with YubiKey GPG
    GNOME_KEYRING_CONTROL = "";
    DISABLE_GNOME_KEYRING = "1";
  };

  # Note: SSH_AUTH_SOCK and GPG_TTY should be set in shell profiles, not session variables
  # PAM doesn't support command substitution like $(tty) or $(gpgconf ...)
  # These should be set dynamically in ~/.bashrc or similar shell init files

  # Use OpenSSH client with FIDO2 (sk) support and disable the legacy agent
  programs.ssh = {
    startAgent = false;
    package = pkgs.openssh.override { withFIDO = true; };
  };

  # Accounts daemon not needed with pass-based keyring
  # services.accounts-daemon.enable = false;

  # Enable dconf for other GNOME applications (not keyring-specific)
  programs.dconf.enable = true;

  # D-Bus packages for keyring removed
  # services.dbus.packages = [ pkgs.gnome-keyring ]; # Not needed

  # Keep essential GNOME services that don't depend on keyring
  services.gnome.glib-networking.enable = true;
  # services.gnome.gnome-online-accounts.enable = false; # Disabled - depends on keyring

  # Systemd user service for pass-secret-service
  # This provides Secret Service API using pass with GPG/YubiKey
  systemd.user.services.pass-secret-service = {
    description = "Pass Secret Service - GPG-based keyring for applications";
    wantedBy = [ "default.target" ];
    # Wait for graphical session to be ready
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.pass-secret-service}/bin/pass_secret_service";
      Restart = "on-failure";
    };
    environment = {
      PASSWORD_STORE_DIR = "%h/.password-store";
      # Import display environment for pinentry dialogs
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-1";
    };
  };
}
