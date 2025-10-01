# bindings.nix
{
  # See https://wiki.hyprland.org/Configuring/Keywords/ for more

  # MAINMOD
  "$mainMod" = "SUPER";

  # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more

  # quickly launch program
  bind = [
    "$mainMod, Space, exec, rofi -show drun"
    "$mainMod SHIFT, Space, exec, rofi -show ssh"
    "$mainMod, E, exec, brave"
    "$mainMod SHIFT, E, exec, google-chrome-stable"
    "SHIFT, Print, exec, grimblast save area - | swappy -f -"
    ", Print, exec, grimblast --notify copy area"

    # COLORPICKER
    "$mainMod SHIFT, P, exec, hyprpicker -a"

    # SHOW KEYS (for screencasting)
    "$mainMod SHIFT, S, exec, pkill wshowkeys || wshowkeys -a bottom -F 'Source Code Pro 24' -t 2 -m 50"

    # "$mainMod SHIFT, X, exec, swaylock --screenshots --clock --indicator --indicator-radius 500 --indicator-thickness 7 --effect-blur 7x5 --effect-pixelate 8 --effect-greyscale --grace 5 --fade-in 2"

    "$mainMod SHIFT, X, exec, hyprlock"
    # "Super_L, exec, pkill rofi || ~/.config/rofi/launcher.sh"
    # "$mainMod, Super_L, exec, bash ~/.config/rofi/powermenu.sh"

    # general bindings
    "$mainMod, T, exec, wezterm"
    "$mainMod, Q, killactive,"
    # "$mainMod SHIFT, M, exit,"
    "$mainMod, Y, togglefloating,"
    "$mainMod, F, fullscreen"
    "$mainMod, I, pin"
    "$mainMod, P, pseudo," # dwindle
    "$mainMod, O, togglesplit," # dwindle

    # Toggle grouped layout
    "$mainMod, U, togglegroup,"
    "$mainMod, bracketleft, changegroupactive, f"
    "$mainMod, bracketright, changegroupactive, b"

    # change gap
    "$mainMod SHIFT, G, exec, hyprctl --batch \"keyword general:gaps_out 5;keyword general:gaps_in 6\""
    "$mainMod, G, exec, hyprctl --batch \"keyword general:gaps_out 0;keyword general:gaps_in 0\""

    # Move focus with mainMod + arrow keys
    "$mainMod, left, movefocus, l"
    "$mainMod, right, movefocus, r"
    "$mainMod, up, movefocus, u"
    "$mainMod, down, movefocus, d"
    "$mainMod, h, movefocus, l"
    "$mainMod, l, movefocus, r"
    "$mainMod, k, movefocus, u"
    "$mainMod, j, movefocus, d"

    # move window in current workspace
    "$mainMod SHIFT, left, swapwindow, l"
    "$mainMod SHIFT, right, swapwindow, r"
    "$mainMod SHIFT, up, swapwindow, u"
    "$mainMod SHIFT, down, swapwindow, d"
    "$mainMod SHIFT, h, swapwindow, l"
    "$mainMod SHIFT, l, swapwindow, r"
    "$mainMod SHIFT, k, swapwindow, u"
    "$mainMod SHIFT, j, swapwindow, d"

    # resize window
    "ALT, R, submap, resize"

    # Switch workspaces with mainMod + [0-9]
    "$mainMod, 1, workspace, 1"
    "$mainMod, 2, workspace, 2"
    "$mainMod, 3, workspace, 3"
    "$mainMod, 4, workspace, 4"
    "$mainMod, 5, workspace, 5"
    "$mainMod, 6, workspace, 6"
    "$mainMod, 7, workspace, 7"
    "$mainMod, 8, workspace, 8"
    "$mainMod, 9, workspace, 9"
    "$mainMod, 0, workspace, 10"
    "$mainMod, C, workspace, Chat"
    "$mainMod, M, workspace, Music"

    "$mainMod CTRL, left, workspace, -1"
    "$mainMod CTRL, right, workspace, +1"
    "$mainMod CTRL, h, workspace, -1"
    "$mainMod CTRL, l, workspace, +1"

    # "$mainMod, period, workspace, e+1"
    # "$mainMod, comma, workspace, e-1"
    # "$mainMod, Q, workspace, QQ"

    # Move active window to a workspace with mainMod + ctrl + [0-9]
    "$mainMod CTRL, 1, movetoworkspace, 1"
    "$mainMod CTRL, 2, movetoworkspace, 2"
    "$mainMod CTRL, 3, movetoworkspace, 3"
    "$mainMod CTRL, 4, movetoworkspace, 4"
    "$mainMod CTRL, 5, movetoworkspace, 5"
    "$mainMod CTRL, 6, movetoworkspace, 6"
    "$mainMod CTRL, 7, movetoworkspace, 7"
    "$mainMod CTRL, 8, movetoworkspace, 8"
    "$mainMod CTRL, 9, movetoworkspace, 9"
    "$mainMod CTRL, 0, movetoworkspace, 10"
    "$mainMod CTRL SHIFT, left, movetoworkspace, -1"
    "$mainMod CTRL SHIFT, right, movetoworkspace, +1"
    "$mainMod CTRL SHIFT, h, movetoworkspace, -1"
    "$mainMod CTRL SHIFT, l, movetoworkspace, +1"

    # same as above, but doesnt switch to the workspace
    "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
    "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
    "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
    "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
    "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
    "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
    "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
    "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
    "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
    "$mainMod SHIFT, 0, movetoworkspacesilent, 10"

    # Scroll through existing workspaces with mainMod + scroll
    "$mainMod, mouse_down, workspace, e+1"
    "$mainMod, mouse_up, workspace, e-1"

    # control volume,brightness,media players
    ", XF86AudioRaiseVolume, exec, pamixer -i 5"
    ", XF86AudioLowerVolume, exec, pamixer -d 5"
    ", XF86AudioMute, exec, pamixer -t"
    ", XF86AudioMicMute, exec, pamixer --default-source -t"
    # Custom mic toggle with notification (for Stream Deck compatibility)
    "$mainMod SHIFT, M, exec, ~/.local/bin/mic-toggle"
    ", XF86MonBrightnessUp, exec, light -A 5"
    ", XF86MonBrightnessDown, exec, light -U 5"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPrev, exec, playerctl previous"
  ];

  # CLIPBOARD
  "exec-once" = [
    "wl-paste --watch cliphist store"
  ];
  # TODO: select old item
  # $ cliphist list | dmenu | cliphist decode | wl-copy
  # TODO: delete old item
  # $ cliphist list | dmenu | cliphist delete
  # TODO: delete query manually
  # $ cliphist delete-query "secret item"
  # TODO: clear database
  # $ cliphist wipe

  # resize window
  # submap = {
  #   resize = {
  #     binde = [
  #       ", left, resizeactive, -30 0"
  #       ", right, resizeactive, 30 0"
  #       ", up, resizeactive, 0 -30"
  #       ", down, resizeactive, 0 30"
  #       ", h, resizeactive, 30 0"
  #       ", l, resizeactive, -30 0"
  #       ", k, resizeactive, 0 -30"
  #       ", j, resizeactive, 0 30"
  #     ];
  #     bind = [
  #       ", escape, submap, reset"
  #     ];
  #   };
  # };

  binde = [
    "CTRL SHIFT, left, resizeactive, -30 0"
    "CTRL SHIFT, right, resizeactive, 30 0"
    "CTRL SHIFT, up, resizeactive, 0 -30"
    "CTRL SHIFT, down, resizeactive, 0 30"
    "CTRL SHIFT, h, resizeactive, -30 0"
    "CTRL SHIFT, l, resizeactive, 30 0"
    "CTRL SHIFT, k, resizeactive, 0 -30"
    "CTRL SHIFT, j, resizeactive, 0 30"
  ];

  bindm = [
    "$mainMod, mouse:272, movewindow"
    "$mainMod, mouse:273, resizewindow"
  ];

  # switch between current and last workspace
  binds = {
    workspace_back_and_forth = false;
    allow_workspace_cycles = false;
  };
  # bind = "$mainMod, slash, workspace, previous"

  # Scratchpads
  # bind = "$mainMod SHIFT, Return, exec, pypr toggle term # code is for '/'"
  # bind = "$mainMod, M, exec, pypr toggle term-mc"
  # bind = "$mainMod, C, exec, pypr toggle term-debugger # C for console"
  # bind = "$mainMod, N, exec, pypr toggle term-nmtui"
  # bind = "$mainMod, B, exec, pypr show bluetooth"
  # bind = "$mainMod, V, exec, pypr show volume"

  # bind = "$mainMod, D, exec, pypr toggle discord"
  # bind = "$mainMod, I, exec, pypr toggle emacs"
  # bind = "$mainMod, O, exec, pypr toggle obs-studio"

  # bind = "SUPER, S, exec, signal-desktop"
  # bind = "SUPER, T, exec, telegram-desktop"
}
