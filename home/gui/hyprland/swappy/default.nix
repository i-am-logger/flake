{ pkgs, ... }:

{
  home.packages = with pkgs ; [
    swappy
  ];

  xdg.configFile."swappy" = {
    source = ./config;
    recursive = true;
  };
}
