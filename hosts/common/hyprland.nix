{ pkgs, ... }: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps to use wayland
    WLR_NO_HARDWARE_CURSORS = "1";  # For VM compatibility
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable display manager with Wayland support
  services.xserver = {
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      sessionPackages = [ pkgs.hyprland ];
    };
    windowManager.hypr.enable = true;
  };

  # Preserve existing libinput settings
  services.libinput = {
    enable = true;
    touchpad.disableWhileTyping = true;
    mouse.disableWhileTyping = true;
  };

  # Add required packages for Hyprland
  environment.systemPackages = with pkgs; [
    waybar       # Status bar
    wofi        # Application launcher
    dunst       # Notification daemon
    libnotify   # Notification library
    wl-clipboard # Clipboard manager
  ];

  # Enable XDG portal for screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
}
