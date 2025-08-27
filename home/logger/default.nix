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
    stateVersion = "25.11";
  };

  imports = [
    ../common.nix
    ./yubikey.nix
    ./jujutsu.nix
    ./git.nix
    ./ssh.nix
  ];
}
