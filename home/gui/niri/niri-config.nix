{ ... }:

let
  input = import ./config/input.nix;
  layout = import ./config/layout.nix;
  bindings = import ./config/bindings.nix;
  animations = import ./config/animations.nix;
  autostart = import ./config/autostart.nix;
  windowRules = import ./config/windowRules.nix;
  environment = import ./config/environment.nix;
  misc = import ./config/misc.nix;
in
{
  xdg.configFile."niri/config.kdl".text = builtins.concatStringsSep "\n" [
    input
    layout
    bindings
    animations
    autostart
    windowRules
    environment
    misc
  ];
}
