{ pkgs
, ...
}:
let
  rebuildCommand =
    if pkgs.stdenv.isDarwin then "darwin-rebuild switch --flake .#" else "nixos-rebuild switch";
in
{
  home.packages = [
    (pkgs.writeScriptBin "update-system" ''
      #!/usr/bin/env bash
      cd ~/.flake
      nix flake update
    '')
    (pkgs.writeScriptBin "rebuild-system" ''
      #!/usr/bin/env bash
      cd ~/.flake
      sudo ${rebuildCommand}
    '')
    (pkgs.writeScriptBin "dp-on" ''
      #!/usr/bin/env bash
      wlr-randr --output eDP-1 --on
    '')
    (pkgs.writeScriptBin "dp-off" ''
      #!/usr/bin/env bash
      wlr-randr --output eDP-1 --off
    '')
  ];
}
