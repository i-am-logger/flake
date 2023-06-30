{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cava
  ];

  xdg.configFile."cava/config".source = ./config;
}