{
  windowrule = [
    # 1Password: float, centered, 60% x 70%
    "match:class ^(1Password)$, float 1, center 1, size 60% 70%"

    # PulseAudio Volume Control
    "match:class ^(org.pulseaudio.pavucontrol)$, float 1, center 1, size 50% 60%"

    # Bluetooth Manager
    "match:class ^(.blueman-manager-wrapped)$, float 1, center 1, size 40% 50%"

    # Network Manager
    "match:class ^(nm-connection-editor)$, float 1, center 1, size 40% 50%"

    # GTK Portal
    "match:class ^(xdg-desktop-portal-gtk)$, float 1, center 1, size 40% 50%"

    # Brave Save Dialog
    "match:class ^(brave)$, match:title ^(Save File)$, float 1, center 1, size 50% 60%"

    # Slack - Main window: tile and suppress maximize
    "match:class ^(Slack)$, match:title ^(.*)$, tile 1, suppress_event maximize"

    # Slack - Hide/suppress menu windows and popups (empty title)
    "match:class ^(Slack)$, match:title ^$, no_focus 1, no_initial_focus 1, float 1, size 0 0, move -1000 -1000"

    # Slack - Handle context menus and dropdowns
    "match:class ^(Slack)$, match:title ^(Context Menu)$, float 1, no_focus 1, size 0 0"
  ];
}
