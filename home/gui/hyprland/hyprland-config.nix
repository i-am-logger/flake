{ lib, ... }:

let
  general = import ./config/general.nix;
  animations = import ./config/animations.nix;
  autostart = import ./config/autostart.nix;
  bindings = import ./config/bindings.nix;
  misc = import ./config/misc.nix;
  decorations = import ./config/decorations.nix;
  input = import ./config/input.nix;
  gestures = import ./config/gestures.nix;
  enviornment = import ./config/enviornment.nix;
  layouts = import ./config/layouts.nix;
  windowRules = import ./config/windowRules.nix;
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
      bindings
      misc
      decorations
      input
      gestures
      enviornment
      layouts
      windowRules
    ];
  };
}
