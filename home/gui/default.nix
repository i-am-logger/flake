{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bibata-cursors
  ];
}

