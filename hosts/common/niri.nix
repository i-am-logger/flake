{ pkgs, ... }:
{
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-gnome
    xwayland-satellite
  ];
}
