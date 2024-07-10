{ config
, pkgs
, pkgs-unstable
, home-manager
, username
, ...
}: {
  ### console TTY
  console = {
    enable = true;
    earlySetup = true;

    font = "ter-powerline-v24b";
    # font = "ter-u32n";
    # keyMap = "dvorak";
    useXkbConfig = true;
    packages = [
      # pkgs.terminus_font
      pkgs.powerline-fonts
    ];
  };

  # services.kmscon = {
  # enable = true;
  # hwRender = true;
  # };
}
