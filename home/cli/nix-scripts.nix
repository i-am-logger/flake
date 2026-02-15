{
  pkgs,
  ...
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
    (pkgs.writeScriptBin "hypr-logout" ''
      #!/usr/bin/env bash
      echo "Logging out and returning to login screen..."
      ${pkgs.hyprland}/bin/hyprctl dispatch exit
    '')
    (pkgs.writeScriptBin "yk-touch" ''
      #!/usr/bin/env bash
      # YubiKey Touch Toggle - Nix Wrapper
      exec ${pkgs.nix}/bin/nix-shell -p yubikey-manager --run "/etc/nixos/scripts/yubikey-touch-toggle.sh $*"
    '')
  ];
}
