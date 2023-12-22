{ ... }: {


  services.xserver.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # theme = "";
    # stopScript = "";
    # startScript = "";
    enableHidpi = true;
    # settings = {

    # };
  };
}
