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
    username = "snick";
    homeDirectory = "/home/snick";
    stateVersion = "25.05";

  };
  #nixpkgs.allowUnfree = true;

  imports = [
    ./common.nix
  ];
}
