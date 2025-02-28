{ pkgs, ... }:

{

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr # Add this

    ];
    config.common.default = "*";

    wlr.enable = true;
  };

  environment.systemPackages = with pkgs; [
    qt6.qtwayland
    # libsForQt6.qtwayland
    # xwaylandvideobridge
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # For Electron apps
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
    WAYLAND_DISPLAY = "wayland-1";

  };

  services.dbus.enable = true;
}
