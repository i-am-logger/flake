# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs
, inputs
, ...
}: {
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.hyprland.enable = true;

  # services.xserver.windowManager.hypr.enable = true;
  # services.xserver.libinput.enable = true;
  # services.xserver.libinput.mouse.disableWhileTyping = true;
}
