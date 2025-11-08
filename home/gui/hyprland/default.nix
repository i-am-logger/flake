{ lib, pkgs, ... }:

let
  hyprlandConfig = import ./hyprland-config.nix { inherit lib pkgs; };
in
{
  imports = [
    # ./waybar  # Replaced with AGS
    # ./ironbar  # Replaced with AGS
    # ../ags
    ./swappy
    hyprlandConfig
    # ./pyprland  # Commented out as in original
  ];

  # GTK configuration
  gtk = {
    enable = true;
    # iconTheme = {
    # };
  };

  # Notification daemon with Stylix theming
  services.mako = {
    enable = true;
    # Stylix handles colors automatically, we just set behavior
    settings = {
      # Behavior
      default-timeout = 5000; # 5 seconds
      ignore-timeout = true; # Don't auto-dismiss critical notifications (like GPG/YubiKey)
      layer = "overlay";

      # Position and sizing - adjusted for better readability
      anchor = "top-center";
      width = 800; # Much wider for big text
      height = 200; # A bit taller too
      margin = "60,20,10,20"; # top,right,bottom,left - lower and more centered
      padding = "20";
      border-size = 2;
      border-radius = 8;

      # Behavior
      max-visible = 5;
      sort = "+time"; # Newest on top

      # Note: Mako doesn't support animations
      # For smooth animations, consider using swaync or dunst instead
    };

    # GPG/YubiKey specific - don't timeout critical notifications
    extraConfig = ''
      [urgency=critical]
      ignore-timeout=1
      default-timeout=0
      
      [app-name="yubikey-touch-detector"]
      ignore-timeout=1
      default-timeout=15000
      border-color=#f38ba8
      
      # Do-not-disturb mode - still show critical notifications (like YubiKey)
      [mode=do-not-disturb]
      invisible=1
      
      [mode=do-not-disturb urgency=critical]
      invisible=0
      
      [mode=do-not-disturb app-name="yubikey-touch-detector"]
      invisible=0
    '';

    # Note: Key bindings are handled via Hyprland keybindings and makoctl
    # Super+N = dismiss newest notification
    # Super+Shift+N = dismiss all notifications  
    # Super+Ctrl+N = toggle do-not-disturb mode
  };

  # DND toggle script
  home.file.".local/bin/toggle-dnd" = {
    text = ''
      #!/usr/bin/env bash
      
      # Toggle mako do-not-disturb mode and show notification feedback
      
      # Get current mode
      current_mode=$(makoctl mode)
      
      # Toggle the mode
      makoctl mode -t do-not-disturb
      
      # Get new mode
      new_mode=$(makoctl mode)
      
      # Show appropriate notification
      if [[ "$new_mode" == "do-not-disturb" ]]; then
          # Temporarily disable DND to show the notification, then re-enable it after delay
          makoctl mode -r do-not-disturb
          notify-send "🔕 Do Not Disturb" "Notifications are now hidden (except critical)" --urgency=normal --expire-time=2500 &
          sleep 2.8  # Wait long enough for notification to be visible
          makoctl mode -s do-not-disturb
      else
          notify-send "🔔 Notifications Enabled" "All notifications are now visible" --urgency=normal --expire-time=3000
      fi
    '';
    executable = true;
  };

  # Home packages
  home.packages = with pkgs; [
    wlr-randr
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    brightnessctl
    swww
    waypaper
    swaybg
    grimblast
    slurp
    swappy
    wl-clipboard
    cliphist
    udiskie
    vlc
    hyprpicker
    wlogout
    networkmanagerapplet
    pavucontrol
    pamixer
    playerctl
    gtk3
  ];

  # Hypr configuration files
  # xdg.configFile."hypr" = {
  #   source = ./config;
  #   recursive = true;
  # };

  # Hyprlock
  # programs.hyprlock = {
  #   enable = true;
  # };
}
