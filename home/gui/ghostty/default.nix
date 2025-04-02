{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
  ];

  xdg.configFile."ghostty/shaders/" = {
    source = ./shaders;
    recursive = true;
  };
  programs.ghostty = {
    enable = true;
    enableFishIntegration = false;
    enableBashIntegration = true;
    installBatSyntax = true;
    # settings reference  https://ghostty.org/docs/config/reference
    settings = {
      font-family = "FireCode Nerd Font";
      font-size = 24;
      font-thicken = true;
      term = "xterm-256color";
      auto-update-channel = "tip";
      background-opacity = 1.0;
      adjust-cell-width = 1;
      adjust-cell-height = 1;
      cursor-style = "block";
      cursor-style-blink = true;
      # window-decoration = false;
      confirm-close-surface = false;
      copy-on-select = true;
      # custom-shader = "shaders/in-game-crt.glsl";
      # custom-shader-animation = true;
    };
  };
}
