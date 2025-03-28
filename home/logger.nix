{ ... }:

{
  manual.manpages.enable = true;

  programs = {
    home-manager.enable = true;
    bash.enable = true;
    zellij.enable = true;
    fzf.enable = true;
  };

  home = {
    username = "logger";
    homeDirectory = "/home/logger";
    stateVersion = "25.05";

  };

  imports = [
    ./common.nix
  ];
}
