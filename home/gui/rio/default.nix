{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rio
  ];

  programs.rio = {
    enable = true;
    settings = {
      # editor = {
      #   program = "hx";
      # };
      confirm-before-quit = false;
      cursor = {
        shape = "block";
        blinking = true;
        blinking-interval = 250;
      };
      renderer = {
        backend = "Automatic";
        target-fps = 120;
        strategy = "events";
      };
      scroll = {
        multiplier = 3.0;
        divider = 1.0;
      };
    };
  };
}
