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
  ];
}
