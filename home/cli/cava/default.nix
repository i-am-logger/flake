{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cava
    # cavalier #gui
  ];

  xdg.configFile."cava/config".source = ./config;
}
