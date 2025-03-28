{ config, pkgs, lib, ... }:
{
  # Install warp-terminal package
  environment.systemPackages = with pkgs; [
    firefox
  ];

  # Configure persistence for warp-terminal
  # environment.persistence."/persist" = {
  #   users.logger = {
  #     directories = [ ".mozilla/firefox" ];
  #   };
  # };
}
