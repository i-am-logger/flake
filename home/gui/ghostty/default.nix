{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
  ];

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    installBatSyntax = true;
    # settings reference  https://ghostty.org/docs/config/reference
    settings = {
      font-family = "FireCode Nerd Font";
      font-size = 18;
      font-thicken = true;
      term = "xterm-256color";
      shell-integration = "fish";
      auto-update-channel = "tip";
      background-opacity = 0.90;
      adjust-cell-width = 1;
      adjust-cell-height = 1;
      cursor-style = "block";
      cursor-style-blink = true;
      window-decoration = false;
      copy-on-select = true;
    };
  };
}
