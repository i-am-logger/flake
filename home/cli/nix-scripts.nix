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
    (pkgs.writeScriptBin "arc-status" (builtins.readFile ../../scripts/arc-status-script.sh))
    (pkgs.writeScriptBin "arc-watch" ''
      #!/usr/bin/env bash
      ${pkgs.watch}/bin/watch -n 1 -c arc-status
    '')
    (pkgs.writeScriptBin "arc-logs" ''
      #!/usr/bin/env bash
      POD=$(${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -n arc-systems -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
      exec ${pkgs.kubectl}/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml logs -n arc-systems "$POD" -f
    '')
    (pkgs.writeScriptBin "arc-tui" (builtins.readFile ../../scripts/arc-tui-script.sh))
  ];
}
