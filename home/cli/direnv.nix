{ pkgs, ... }:

{
  home.packages = with pkgs; [
    direnv
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
    # direnvrcExtra = ''
    #   echo "Loaded direnv!"
    # '';
  };
}
