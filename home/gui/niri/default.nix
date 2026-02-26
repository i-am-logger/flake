{ pkgs, ... }:
{
  imports = [
    ./niri-config.nix
    ./eww
  ];

  gtk.enable = true;

  home.packages = with pkgs; [
    swaybg
    grim
    slurp
    swaylock-effects
    wl-clipboard
    cliphist
    brightnessctl
    pamixer
    playerctl
    pavucontrol
    networkmanagerapplet
    wlogout
    nerd-fonts.fira-code
  ];
}
