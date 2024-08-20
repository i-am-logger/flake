{
  exec-once = [
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    # "waybar &"
    "pypr &"
    "blueman-applet &"
    "nm-applet --indicator &"
    "1password --silent &"
    "wl-paste --watch cliphist store"
  ];
}
