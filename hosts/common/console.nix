{ config, pkgs, pkgs-unstable, home-manager, username, ... }:

{
  ### console TTY
  console = {
    enable = true;
    earlySetup = true;

    font = "ter-powerline-v32b";
    #keyMap = "he";
    useXkbConfig = true;
    packages = [
      pkgs.terminus_font
      pkgs.powerline-fonts
    ];
  };
}
