{ pkgs, ... }: {
  home.packages = with pkgs; [
    kitty
  ];

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = true;
      window_alert_on_bell = " yes";
      bell_on_tab = "🔔 ";
      disable_ligatures = "never";
      cursor_text_color = "background";
      cursor_shape = "block";
      cursor_blink_internal = 1;
      cursor_stop_blinking_after = 0;
      detect_urls = "yes";
      show_hyperlink_targets = "yes";
      copy_on_select = "yes";
      dim_opacity = 0;
      touch_scroll_multiplier = 7;
      scrollback_lines = 100000;
      scrollback_pager = "hx";
      sync_to_monitor = "yes";
    };
  };
}
