{ pkgs, ... }:
{
  home.packages = with pkgs; [
    warp-terminal
  ];

  xdg.configFile."warp" = {
    source = ./config;
    recursive = true;
  };

  programs.warp = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      # Basic settings for Warp
      theme = "default";
      font_family = "FiraCode Nerd Font";
      font_size = 14;
      window_padding = {
        x = 10;
        y = 10;
      };
    };
  };
}

