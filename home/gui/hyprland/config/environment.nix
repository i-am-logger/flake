{
  monitor = [
    ",highrr,auto,1"
    # ", preferred, auto, 1"
    # "eDP-1,disable"
  ];

  xwayland = {
    force_zero_scaling = true;
  };

  env = [
    "XCURSOR_SIZE,24"
    "XCURSOR_THEME,Bibata-Modern-Classic"
    "GDK_SCALE,2"
    "XDG_SESSION_TYPE,wayland"
    "WLR_NO_HARDWARE_CURSORS,1"
    "HYPRLAND_SOCKET_PATH,/tmp/hypr"
  ];
}
