{ pkgs, ... }:

{
  programs.eww = {
    enable = true;
    configDir = ./config;
  };

  home.packages = with pkgs; [
    cava
    fftw
    iniparser
    jq
    socat
    font-awesome
    papirus-icon-theme
    adwaita-icon-theme
    blueman
  ];
}
