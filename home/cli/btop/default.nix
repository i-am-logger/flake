{ pkgs, ... }:

{
  # home.packages = with pkgs; [ btop ];

  # xdg.desktopEntries.btop = {
  #   type = "Application";
  #   name = "Btop";
  #   exec = "btop";
  #   terminal = true;
  #   genericName = "Resource monitor";
  # };

  programs.btop = {
    enable = true;
  };

  # xdg.configFile."btop/" = {
  #   source = ./config;
  #   recursive = true;
  # };
}
