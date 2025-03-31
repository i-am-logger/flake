{ lib, ... }:
{
  home.packages = [

  ];

  programs.starship = {
    enable = true;
  };

  xdg.configFile."starship.toml" = lib.mkForce {
    source = ./starship.toml;
  };
}
