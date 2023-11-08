{ pkgs
, config
, lib
, ...
}: {
  home.packages = with pkgs; [
    ranger
    ueberzug # image preview
    poppler_utils # pdf to text
    mupdf # pdf graphical viewer
  ];

  # TODO: devicons
  # git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons

  xdg.configFile."ranger/" = {
    source = ./config;
    recursive = true;
  };
}
