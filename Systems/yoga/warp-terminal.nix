{ config, pkgs, lib, ... }:
{
  # Allow unfree packages specifically for warp-terminal
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or pkg.name) [
    "warp-terminal"
  ];

  # Install warp-terminal package
  environment.systemPackages = with pkgs; [
    warp-terminal
  ];

  # Configure persistence for warp-terminal
  # environment.persistence."/persist" = {
  #   users.logger = {
  #     directories = [
  #       ".config/warp-terminal"
  #       ".local/state/warp-terminal"  
  #     ];
  #   };
  # };
}
