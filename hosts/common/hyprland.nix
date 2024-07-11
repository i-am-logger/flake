{ ... }: {
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs.hyprland.enable = true;

  services.xserver.windowManager.hypr.enable = true;
  services.libinput.enable = true;
  services.libinput.touchpad.disableWhileTyping = true;
  services.libinput.mouse.disableWhileTyping = true;
}
