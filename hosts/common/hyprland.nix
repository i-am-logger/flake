# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  inputs,
  ...
}: {
  # environment.systemPackages = with pkgs; [
  # hyprland
  # inputs.hypr-contrib.packages.${pkgs.system}.grimblast
  # inputs.hypr-contrib.packages.${pkgs.system}.scratchpad
  # ];

  #programs.hyprland = {
  #  enable = true;
  #  #nvidiaPatches = true;

  #  xwayland = {
  #    enable = true;
  #    hidpi = true;
  #  };
  #};

  #services.xserver.windowManager.hypr.enable = true;
}
