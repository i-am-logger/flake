# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{ pkgs, ... }:
{
  imports = [
    common/console.nix

    common/system.nix
    common/security/security.nix
    common/security/1password.nix
    common/nix.nix
    common/nvidia.nix

    common/environment.nix
    common/hyprland.nix
    common/binfmt.nix
    common/appimage.nix
    common/direnv.nix
    common/xdg.nix
    common/v4l2loopback.nix
    common/docker.nix
    common/streamdeck.nix
    # common/ollama.nix  # Disabled on skyspy-dev
    users/logger.nix
  ];

  services.usbmuxd.enable = true;

  services.fwupd.enable = true; # firmware update
  services.trezord.enable = true;
  # security.pam.services.swaylock = { };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
}
