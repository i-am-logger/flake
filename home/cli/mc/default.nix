{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mc
  ];

  xdg.configFile."mc" = {
    source = ./config;
    recursive = true;
  };
}
