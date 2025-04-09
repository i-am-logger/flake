{
  exec-once = [
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    # "gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Amber'"
    # "gsettings set org.gnome.desktop.interface cursor-size 24"
    "1password --silent &"
    "wl-paste --watch cliphist store"
  ];
}
