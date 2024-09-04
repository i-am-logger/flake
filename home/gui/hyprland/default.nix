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

  # Cursor configuration (commented out as in original)
  # home.pointerCursor = {
  #   package = pkgs.gnome.adwaita-icon-theme;
  #   name = "Adwaita";
  #   gtk.enable = true;
  # };

  # GTK configuration
  gtk = {
    enable = true;
    # iconTheme = {
    # };
  };

  # Services
  services = {
    # blueman.enable = true;  # Commented out as in original
    blueman-applet.enable = true;
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
  programs.hyprlock = {
    enable = true;
  };
}
