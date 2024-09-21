{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xdg-utils
  ];

  xdg = {
    enable = true;
    mime.enable = true;
    userDirs.enable = true;
    userDirs.createDirectories = true;
  };
}
