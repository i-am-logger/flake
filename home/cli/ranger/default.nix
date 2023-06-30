{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    ranger
  ];

  xdg.configFile."ranger/" = {
    source = ./config;
    recursive = true;
  };
}
