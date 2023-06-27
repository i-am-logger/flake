{ pkgs, ... }:

{
#  home.packages = with pkgs; [
#    wlr-randr
#    mako
#    waybar
#    pipewire
#    wireplumber
#    xdg-desktop-portal-hyprland

#    polkit-kde-agent #TODO: configure and get rid of gnome dekstop manager
#    #libsForQt5.full -- error of insecure
#    qt6.full
#    wineWowPackages.waylandFull
#    winetricks
    
    #swaylock
    #swaylock-effects
#  ];

  

  wayland.windowManager.hyprland = {
    enable = true;

    xwayland = {
      enable = true;
      hidpi = true;
    };

    #nvidiaPatches = true;


    
    extraConfig = ''

      #------------#
      # AUTO START #
      #------------#
      exec-once = mako &
      exec-once = waybar &
      
      #-------------#
      # ENVIORNMENT #
      #-------------#
      env = LIBVA_DRIVER_NAME,nvidia
      env = XDG_SESSION_TYPE,wayland
      env = GBM_BACKEND,nvidia-drm
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = WLR_NO_HARDWARE_CURSORS,1

      #---------#
      # MONITOR #
      #---------#
      #monitor=, preferred, auto, 1
      #monitor=DP-3, 5120x1440@239.761, 0x0, 1

      #---------#
      # MAINMOD #
      #---------#
      $mainMod = ALT

      #---------------------#
      # NEW TERMINAL WINDOW #
      #---------------------#
      bind = SUPER, Return, exec, kitty

      #-------#
      # INPUT #
      #-------#
      input {
        kb_layout = us
        kb_variant = us,il
        kb_model =
        kb_options = caps:escape
        kb_rules =
        repeat_rate = 25
        repeat_delay = 250

        left_handed = true
        follow_mouse = 2 # 0|1|2|3
        float_switch_override_focus = 2
        numlock_by_default = off
        natural_scroll = yes
        touchpad {
          natural_scroll = yes
          disable_while_typing = yes
        }

        sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
      }

      #---------#
      # GENERAL #
      #---------#
      general {
        gaps_in = 6
        gaps_out = 10
        border_size = 4

        layout = dwindle # master|dwindle
      }

      dwindle {
        pseudotile = yes 
        force_split = 2 
        preserve_split = yes 
        special_scale_factor = 0.5
        split_width_multiplier = 1.0 
        no_gaps_when_only = false
        use_active_for_splits = true
      }

      master {
        new_is_master = true
        orientation = center
        always_center_master = true
        special_scale_factor = 0.8
        #new_is_master = true
        no_gaps_when_only = false
      }

      
      # cursor_inactive_timeout = 0

      #-------------#
      # DECORATIONS #
      #-------------#
      decoration {
        multisample_edges = true
        active_opacity = 0.8
        inactive_opacity = 0.8
        fullscreen_opacity = 0.8
        rounding = 8
        blur = yes 
        blur_size = 5
        blur_passes = 1
        blur_new_optimizations = true
        blur_xray = true

        drop_shadow = true
        shadow_range = 4
        shadow_render_power = 3
        shadow_ignore_window = true
      # col.shadow = 
      # col.shadow_inactive
      # shadow_offset
        dim_inactive = true
        dim_strength = 0.3 #0.0 ~ 1.0
        blur_ignore_opacity = false
        col.shadow = rgba(1a1a1aee)
      }

      #------------#
      # ANIMATIONS #
      # -----------#
      # animations {
      #   enabled = yes
      #
      #   bezier = easeOutElastic, 0.05, 0.9, 0.1, 1.05
      #   # bezier=overshot,0.05,0.9,0.1,1.1
      #
      #   animation = windows, 1, 5, easeOutElastic
      #   animation = windowsOut, 1, 5, default, popin 80%
      #   animation = border, 1, 8, default
      #   animation = fade, 1, 5, default
      #   animation = workspaces, 1, 6, default
      # }
      #animations {
      #  enabled=1
      #  bezier = overshot, 0.13, 0.99, 0.29, 1.1
      #  animation = windows, 1, 4, overshot, slide
      #  animation = windowsOut, 1, 5, default, popin 80%
      #  animation = border, 1, 5, default
      #  animation = fade, 1, 8, default
      #  animation = workspaces, 1, 6, overshot, slidevert
      #}

      #----------#
      # GESTURES #
      #----------#
      gestures {
        workspace_swipe = true
        workspace_swipe_fingers = 4
        workspace_swipe_distance = 250
        workspace_swipe_invert = true
        workspace_swipe_min_speed_to_force = 15
        workspace_swipe_cancel_ratio = 0.5
        workspace_swipe_create_new = false
      }

      #------#
      # MISC #
      #------#
      misc {
        #disable_autoreload = true
        disable_hyprland_logo = true
        always_follow_on_dnd = true
        layers_hog_keyboard_focus = true
        animate_manual_resizes = true
        enable_swallow = true
        swallow_regex =
        focus_on_activate = true
      }

      device:epic mouse V1 {
        sensitivity = -0.5
      }

      bind = $mainMod      , Return , exec, kitty fish
      bind = $mainMod SHIFT, Return , exec, kitty --class="termfloat" fish
      bind = $mainMod      , Q      , killactive,
     #bind = $mainMod SHIFT, Q      , exit,
      bind = $mainMod SHIFT, Space  , togglefloating,
      bind = $mainMod      , F      , fullscreen
      bind = $mainMod      , Y      , pin
      bind = $mainMod      , P      , pseudo, # dwindle
      bind = $mainMod      , J      , togglesplit, # dwindle

      #-----------------------#
      # Toggle grouped layout #
      #-----------------------#
      bind = $mainMod, K  , togglegroup,
      bind = $mainMod, Tab, changegroupactive, f

      #------------#
      # change gap #
      #------------#
      bind = $mainMod SHIFT, G, exec, hyprctl --batch "keyword general:gaps_out 5;keyword general:gaps_in 6"
      bind = $mainMod      , G, exec, hyprctl --batch "keyword general:gaps_out 0;keyword general:gaps_in 0"

      #--------------------------------------#
      # Move focus with mainMod + arrow keys #
      #--------------------------------------#
      bind = $mainMod, left  , movefocus, l
      bind = $mainMod, right , movefocus, r
      bind = $mainMod, up    , movefocus, u
      bind = $mainMod, down  , movefocus, d
   
      #----------------------------------#
      # move window in current workspace #
      #----------------------------------#
      bind = $mainMod SHIFT, left  , movewindow, l
      bind = $mainMod SHIFT, right , movewindow, r
      bind = $mainMod SHIFT, up    , movewindow, u
      bind = $mainMod SHIFT, down  , movewindow, d
      
      #---------------#
      # resize window #
      #---------------#
      bind   =  ALT,R,submap,resize
      submap =  resize
      binde  =        , right , resizeactive, 15 0
      binde  =        , left  , resizeactive, -15 0
      binde  =        , up    , resizeactive, 0 -15
      binde  =        , down  , resizeactive, 0 15
      binde  =        , l     , resizeactive, 15 0
      binde  =        , h     , resizeactive, -15 0
      binde  =        , k     , resizeactive, 0 -15
      binde  =        , j     , resizeactive, 0 15
      bind   =        , escape, submap      , reset 
      submap = reset

      binde=CTRL SHIFT, left  , resizeactive, -15 0
      binde=CTRL SHIFT, right , resizeactive, 15 0
      binde=CTRL SHIFT, up    , resizeactive, 0 -15
      binde=CTRL SHIFT, down  , resizeactive, 0 15
      binde=CTRL SHIFT, l     , resizeactive, 15 0
      binde=CTRL SHIFT, h     , resizeactive, -15 0
      binde=CTRL SHIFT, k     , resizeactive, 0 -15
      binde=CTRL SHIFT, j     , resizeactive, 0 15

      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      #----------------------------------------#
      # Switch workspaces with mainMod + [0-9] #
      #----------------------------------------#
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      bind = $mainMod, C, workspace, Chat
      bind = $mainMod, M, workspace, Music
      
      #bind = $mainMod, L, workspace, +1
      #bind = $mainMod, H, workspace, -1
      #bind = $mainMod, period, workspace, e+1
      #bind = $mainMod, comma, workspace,e-1
      #bind = $mainMod, Q, workspace,QQ

      #---------------------------------------------------------------#
      # Move active window to a workspace with mainMod + ctrl + [0-9] #
      #---------------------------------------------------------------#
      bind = $mainMod CTRL, 1    , movetoworkspace, 1
      bind = $mainMod CTRL, 2    , movetoworkspace, 2
      bind = $mainMod CTRL, 3    , movetoworkspace, 3
      bind = $mainMod CTRL, 4    , movetoworkspace, 4
      bind = $mainMod CTRL, 5    , movetoworkspace, 5
      bind = $mainMod CTRL, 6    , movetoworkspace, 6
      bind = $mainMod CTRL, 7    , movetoworkspace, 7
      bind = $mainMod CTRL, 8    , movetoworkspace, 8
      bind = $mainMod CTRL, 9    , movetoworkspace, 9
      bind = $mainMod CTRL, 0    , movetoworkspace, 10
      bind = $mainMod CTRL, left , movetoworkspace, -1
      bind = $mainMod CTRL, right, movetoworkspace, +1

      # same as above, but doesnt switch to the workspace
      bind = $mainMod SHIFT , 1, movetoworkspacesilent, 1
      bind = $mainMod SHIFT , 2, movetoworkspacesilent, 2
      bind = $mainMod SHIFT , 3, movetoworkspacesilent, 3
      bind = $mainMod SHIFT , 4, movetoworkspacesilent, 4
      bind = $mainMod SHIFT , 5, movetoworkspacesilent, 5
      bind = $mainMod SHIFT , 6, movetoworkspacesilent, 6
      bind = $mainMod SHIFT , 7, movetoworkspacesilent, 7
      bind = $mainMod SHIFT , 8, movetoworkspacesilent, 8
      bind = $mainMod SHIFT , 9, movetoworkspacesilent, 9
      bind = $mainMod SHIFT , 0, movetoworkspacesilent, 10
      
      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up  , workspace, e-1

      #-------------------------------------------#
      # switch between current and last workspace #
      #-------------------------------------------#
      binds {
           workspace_back_and_forth = 0 
           allow_workspace_cycles = 0
      }
      #bind=$mainMod,slash,workspace,previous

      #-----------------------------------------#
      # control volume,brightness,media players-#
      #-----------------------------------------#
      bind=, XF86AudioRaiseVolume , exec, pamixer -i 5
      bind=, XF86AudioLowerVolume , exec, pamixer -d 5
      bind=, XF86AudioMute        , exec, pamixer -t
      bind=, XF86AudioMicMute     , exec, pamixer --default-source -t
      bind=, XF86MonBrightnessUp  , exec, light -A 5
      bind=, XF86MonBrightnessDown, exec, light -U 5
      bind=, XF86AudioPlay        , exec, mpc -q toggle 
      bind=, XF86AudioNext        , exec, mpc -q next 
      bind=, XF86AudioPrev        , exec, mpc -q prev

      #------------------------#
      # quickly launch program #
      #------------------------# 
      #bind=$mainMod       ,B           , exec, firefox
      bind=$mainMod       ,B           , exec, google-chrome-stable
      bind=$mainMod SHIFT ,X           , exec, myswaylock
      #bind=              ,Super_L     , exec, pkill rofi || ~/.config/rofi/launcher.sh
      #bind=$mainMod      ,Super_L     , exec, bash ~/.config/rofi/powermenu.sh
      #bind=$mainMod      ,A           , exec, grimblast_watermark
      #bind=$mainMod      ,bracketleft , exec, grimblast --notify --cursor  copysave area ~/Pictures/$(date "+%Y-%m-%d"T"%H:%M:%S_no_watermark").png
      #bind=$mainMod      ,bracketright, exec, grimblast --notify --cursor  copy area
    '';
  };
}