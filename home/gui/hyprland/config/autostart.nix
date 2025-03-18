{
  exec-once = [
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'"
    "gsettings set org.gnome.desktop.interface cursor-size 24"
    # "waybar &"
    "pypr &"
    "blueman-applet &"
    "nm-applet --indicator &"
    "1password --silent &"
    "wl-paste --watch cliphist store"
  ];
}
