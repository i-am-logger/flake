{
  general = {
    gaps_in = 10;
    gaps_out = 10;
    border_size = 3;
    layout = "dwindle";
  };

  group = {
    groupbar = {
      font_family = "FiraCode Nerd Font";
      font_size = 28;
      height = 32;
      indicator_height = 5;
    };
  };

  # Layer rules for better performance
  layerrule = [
    "match:namespace walker, no_anim 1"
  ];

}
