{ pkgs, ... }:

{
  home.packages = with pkgs; [
    direnv
  ];

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
}
