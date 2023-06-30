{ config, lib, pkgs, ... }:

{
  programs.lsd = {
    enable = true;
    enableAliases = true;
    settings = {
      indicators = true;
      recursion = {
        depth = 2;
      };
      sorting = {
        dir-grouping = "first";
      };
      symlink-arrow = "⇒";
      header = true;
    };
  };
}
