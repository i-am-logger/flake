{ lib, ... }:

let
  general = import ./config/general.nix;
  animations = import ./config/animations.nix;
  autostart = import ./config/autostart.nix;
  environment = import ./config/environment.nix;
  # bindings = import ./config/bindings.nix;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
    settings = lib.mkMerge [
      general
      animations
      autostart
      environment
      # bindings
    ];
  };
}
