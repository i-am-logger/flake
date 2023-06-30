{pkgs, ...}: {
  home.packages = with pkgs; [
    kitty
  ];

  #  xdg.configFile."kitty/" = {
  #    source = ./config;
  #    recursive = true;
  #  };

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = true;
      window_alert_on_bell = " yes";
      bell_on_tab = "🔔 ";
      #allow_remote_control = true;
      window_padding_width = "16";
      "disable_ligatures" = "never";
      #      background_opacity = "0.8";
      #include = "mytheme.conf";
      cursor_text_color = "background";
      cursor_shape = "block";
      cursor_blink_internal = 1;
      cursor_stop_blinking_after = 0;
      detect_urls = "yes";
      show_hyperlink_targets = "yes";
      copy_on_select = "yes";
      dim_opacity = 0;
      #wheel_scroll_multiplier = 1;
      touch_scroll_multiplier = 8;
    };
  };
}
