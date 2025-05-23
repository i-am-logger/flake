{
  input = {
    #kb_layout = us
    #kb_variant = us,il
    #kb_model =
    #kb_options = caps:escape
    #kb_rules =
    #repeat_rate = 30
    repeat_delay = 200;
    left_handed = false;
    #follow_mouse = 2 # 0|1|2|3
    float_switch_override_focus = 2;
    numlock_by_default = "off";
    natural_scroll = "yes";

    touchpad = {
      natural_scroll = 1;
      disable_while_typing = true;
      #clickfinger_behavior = true
      #middle_button_emulation = true
      scroll_factor = 0.3;
    };

    sensitivity = -0.3; # -1.0 - 1.0, 0 means no modification.
  };
}
# device:syna2ba6:00-06cb:cefe-touchpad {
#   disable_while_typing = true
# }
