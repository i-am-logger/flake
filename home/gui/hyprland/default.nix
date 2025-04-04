{ lib, pkgs, ... }:

let
  hyprlandConfig = import ./hyprland-config.nix { inherit lib pkgs; };
in
{
  imports = [
    ./waybar
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

  # Home packages
  home.packages = with pkgs; [
    wlr-randr
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
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
    rofi-wayland
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
