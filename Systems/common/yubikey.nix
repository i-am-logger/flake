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
    gopass # Go-based password manager with better secret service support
    ripasso-cursive # Rust-based password manager (TUI)
    libsecret # Required for Electron apps to use Secret Service
    libnotify # Desktop notifications (notify-send)
    yubikey-touch-detector # YubiKey touch notifications
    # mako # Notification daemon moved to hyprland.nix
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
        # Updated YubiKey credentials to match current YubiKey
        authfile = pkgs.writeText "u2f_keys" ''
          logger:o5T6TQ5iYu64pwX0SPEGJWA8jNvLMfpIEnyqvc9cpy3TzIYfDXkACyzh/u3mjZHsKocDHlneOxaXAs6JUsT1+Q==,jnyAExu5aDjmlzHvRTjluntGbp4lWR/rpVhS854dtZo52YFKdt9dQXHmy/tdgqn0K6thceCM0B2SBe3hhI4BDw==,es256,+presence:hF8seRUCsywV9K98qRDZjoSOicDlTEmvoiJpqmNzr00K822BGj3kNIwUWxdrQJD5NCKoF6Q+g7A/7kfNWRdV2g==,ZJOBZWHoeCr1L9zO1kWahMFGYb2INutB2ueIMGxdl2DqIoskKgEEMtUU1TIwqOS0S+AygNmer3f+su4fEpkMNA==,es256,+presence
        '';
        cue = true;
        interactive = true;
        max_devices = 2;
        # Enable desktop notifications for touch requests
        authpending_file = "/var/run/user/%i/pam-u2f-authpending";
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

  # Disable system SSH agent
  programs.ssh.startAgent = false;

  # Accounts daemon not needed with pass-based keyring
  # services.accounts-daemon.enable = false;

  # Enable dconf for other GNOME applications (not keyring-specific)
  programs.dconf.enable = true;

  # D-Bus packages for keyring removed
  # services.dbus.packages = [ pkgs.gnome-keyring ]; # Not needed

  # Keep essential GNOME services that don't depend on keyring
  services.gnome.glib-networking.enable = true;
  # services.gnome.gnome-online-accounts.enable = false; # Disabled - depends on keyring

  # Note: gopass has built-in secret service support
  # No separate service needed - gopass can act as a Secret Service provider
  # Applications can access passwords via libsecret API with gopass

  # Note: Notification daemon service moved to hosts/common/hyprland.nix

  # YubiKey touch detector service for desktop notifications
  systemd.user.services.yubikey-touch-detector = {
    enable = true;
    description = "Detects when YubiKey is waiting for a touch";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
      Restart = "always";
      RestartSec = 1;
      # Environment for notifications in Hyprland
      Environment = [
        "PATH=${pkgs.libnotify}/bin"
      ];
    };
  };
}
