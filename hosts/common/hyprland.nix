{ pkgs, ... }:
{
  # Create /tmp/hypr directory with correct permissions
  systemd.tmpfiles.rules = [
    "d /tmp/hypr 1777 root root -"
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.xserver = {
    enable = true;
    windowManager.hypr.enable = true;
  };
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  # services.windowManager.hypr.enable = true;

  # Enable XDG portal for screen sharing
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  # };
}
