{
  monitor = [
    ",highrr,auto,1"
    # monitor=, preferred, auto, 1

    # TODO: for handlink
    "HDMI-A-1, 2560x1440@144.005997,0x0, 1.0"
    # monitor=eDP-1,  2560x1600@240.001999,2560x0, 1.0
    #monitor=HDMI-A-1, 5120x1440@119.987999,2560x0, 1.0
    # monitor=HDMI-A-1, 4096x2160@59.94,0x0, 1.0
  ];

  #----------#
  # XWAYLAND #
  #-----------#

  xwayland = {
    force_zero_scaling = true;
  };

  #-------------#
  # ENVIORNMENT #
  #-------------#

  env = [
    "XCURSOR_SIZE, 12"
    "GDK_SCALE,2
"
    #env = LIBVA_DRIVER_NAME,nvidia
    "XDG_SESSION_TYPE,wayland"
    #env = GBM_BACKEND,nvidia-drm
    #env = __GLX_VENDOR_LIBRARY_NAME,nvidia
    "WLR_NO_HARDWARE_CURSORS,1"
    # env = KITTY_DISABLE_WAYLAND,1
  ];
  # Example per-device config
  # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
  # device:epic-mouse-v1 {
  #   sensitivity = -0.5
  #} 
}