''
binds {
    // App launchers
    Mod+Space { spawn "walker" "-p" "Start…" "-w" "1000" "-h" "700"; }
    Mod+Shift+Space { spawn "walker" "--modules" "ssh" "-w" "1000" "-h" "700"; }
    Mod+E { spawn "brave"; }
    Mod+Shift+E { spawn "google-chrome-stable"; }
    Mod+T { spawn "wezterm"; }

    // Walker additional modes
    Mod+Period { spawn "walker" "-p" "Find files… (type . then filename)" "-w" "1000" "-h" "700" "-q" "."; }
    Mod+Equal { spawn "walker" "-p" "Calculator… (type = then expression)" "-w" "1000" "-h" "700" "-q" "="; }
    Mod+Semicolon { spawn "walker" "-p" "Emojis… (type : then emoji name)" "-w" "1000" "-h" "700" "-q" ":"; }

    // Screenshots
    Shift+Print { screenshot; }
    Print { screenshot-screen; }

    // Lock screen
    Mod+Shift+X { spawn "swaylock"; }

    // Window management
    Mod+Q { close-window; }
    Mod+Y { toggle-window-floating; }
    Mod+F { fullscreen-window; }

    // Focus
    Mod+H { focus-column-left; }
    Mod+L { focus-column-right; }
    Mod+K { focus-window-up; }
    Mod+J { focus-window-down; }
    Mod+Left { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+Up { focus-window-up; }
    Mod+Down { focus-window-down; }

    // Move windows
    Mod+Shift+H { move-column-left; }
    Mod+Shift+L { move-column-right; }
    Mod+Shift+K { move-window-up; }
    Mod+Shift+J { move-window-down; }
    Mod+Shift+Left { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+Up { move-window-up; }
    Mod+Shift+Down { move-window-down; }

    // Workspaces
    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    // Move window to workspace
    Mod+Ctrl+1 { move-window-to-workspace 1; }
    Mod+Ctrl+2 { move-window-to-workspace 2; }
    Mod+Ctrl+3 { move-window-to-workspace 3; }
    Mod+Ctrl+4 { move-window-to-workspace 4; }
    Mod+Ctrl+5 { move-window-to-workspace 5; }
    Mod+Ctrl+6 { move-window-to-workspace 6; }
    Mod+Ctrl+7 { move-window-to-workspace 7; }
    Mod+Ctrl+8 { move-window-to-workspace 8; }
    Mod+Ctrl+9 { move-window-to-workspace 9; }

    // Navigate workspaces
    Mod+Ctrl+H { focus-workspace-up; }
    Mod+Ctrl+L { focus-workspace-down; }
    Mod+Ctrl+Left { focus-workspace-up; }
    Mod+Ctrl+Right { focus-workspace-down; }

    // Resize
    Ctrl+Shift+H { set-column-width "+5%"; }
    Ctrl+Shift+L { set-column-width "-5%"; }
    Ctrl+Shift+K { set-window-height "-5%"; }
    Ctrl+Shift+J { set-window-height "+5%"; }
    Ctrl+Shift+Left { set-column-width "+5%"; }
    Ctrl+Shift+Right { set-column-width "-5%"; }
    Ctrl+Shift+Up { set-window-height "-5%"; }
    Ctrl+Shift+Down { set-window-height "+5%"; }

    // Volume and brightness
    XF86AudioRaiseVolume { spawn "pamixer" "-i" "5"; }
    XF86AudioLowerVolume { spawn "pamixer" "-d" "5"; }
    XF86AudioMute { spawn "pamixer" "-t"; }
    XF86AudioMicMute { spawn "pamixer" "--default-source" "-t"; }
    XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
    XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
    XF86AudioPlay { spawn "playerctl" "play-pause"; }
    XF86AudioNext { spawn "playerctl" "next"; }
    XF86AudioPrev { spawn "playerctl" "previous"; }

    // Notifications
    Mod+N { spawn "makoctl" "dismiss"; }
    Mod+Shift+N { spawn "makoctl" "dismiss" "--all"; }
    Mod+Ctrl+N { spawn "sh" "-c" "~/.local/bin/toggle-dnd"; }

    // Niri extras
    Mod+O { toggle-overview; }
    Mod+P { switch-preset-column-width; }
    Mod+Shift+P { switch-preset-window-height; }
    Mod+BracketLeft { consume-or-expel-window-left; }
    Mod+BracketRight { consume-or-expel-window-right; }

    // Mouse scroll workspaces
    Mod+WheelScrollDown { focus-workspace-down; }
    Mod+WheelScrollUp { focus-workspace-up; }
}
''
