{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    pkgs.neofetch
    pkgs.w3m
    pkgs.imagemagick
  ];

  xdg.configFile."neofetch/" = {
    source = ./config;
    #target = "neofetch";
    recursive = true;
  };
}
