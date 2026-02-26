''
spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "eww" "daemon"
spawn-sh-at-startup "sleep 0.5 && eww open-many bar bottom_bar bottom_bar2"
spawn-at-startup "swaybg" "-m" "fill" "-i" "/etc/nixos/Themes/Wallpapers/skyspy-wallpaper-2560x1600.png"
spawn-at-startup "1password" "--silent"
spawn-sh-at-startup "wl-paste --watch cliphist store"
''
