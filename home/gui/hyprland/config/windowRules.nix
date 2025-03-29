{
  windowrule = [ ];  # Empty since we're converting all rules to windowrulev2

  windowrulev2 = [
    # 1Password: 20% margins from edges
    "float,class:^(1Password)$"
    "center,class:^(1Password)$"
    "size 60% 70%,class:^(1Password)$"
    "workspace 20% 20%,class:^(1Password)$"

    # PulseAudio Volume Control
    "float,class:^(org.pulseaudio.pavucontrol)$"
    "center,class:^(org.pulseaudio.pavucontrol)$"
    "size 50% 60%,class:^(org.pulseaudio.pavucontrol)$"
    "workspace 25% 20%,class:^(org.pulseaudio.pavucontrol)$"

    # Bluetooth Manager
    "float,class:^(.blueman-manager-wrapped)$"
    "center,class:^(.blueman-manager-wrapped)$"
    "size 40% 50%,class:^(.blueman-manager-wrapped)$"
    "workspace 30% 25%,class:^(.blueman-manager-wrapped)$"

    # Network Manager
    "float,class:^(nm-connection-editor)$"
    "center,class:^(nm-connection-editor)$"
    "size 40% 50%,class:^(nm-connection-editor)$"
    "workspace 30% 25%,class:^(nm-connection-editor)$"

    # GTK Portal
    "float,class:^(xdg-desktop-portal-gtk)$"
    "center,class:^(xdg-desktop-portal-gtk)$"
    "size 40% 50%,class:^(xdg-desktop-portal-gtk)$"
    "workspace 30% 25%,class:^(xdg-desktop-portal-gtk)$"

    # Brave Save Dialog
    "float,class:^(brave)$,title:^(Save File)$"
    "center,class:^(brave)$,title:^(Save File)$"
    "size 50% 60%,class:^(brave)$,title:^(Save File)$"
    "workspace 25% 20%,class:^(brave)$,title:^(Save File)$"
  ];

  # Converted Thunar rules in new format (kept as comments):
  # "float,class:^(thunar)$"
  # "center,class:^(thunar)$"
  # "size 50% 60%,class:^(thunar)$"
  # "workspace 25% 20%,class:^(thunar)$"
  # "animation popin,class:^(thunar)$"
}
