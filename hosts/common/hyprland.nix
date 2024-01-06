# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs
, inputs
, ...
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
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.xserver.windowManager.hypr.enable = true;
  services.xserver.libinput.enable = true;
  services.xserver.libinput.mouse.disableWhileTyping = true;

}
