{
  general = {
    gaps_in = 10;
    gaps_out = 10;
    border_size = 3;
    layout = "dwindle";
  };

  group = {
    groupbar = {
      font_family = "Fira Code Nerd Font";
      font_size = 28;
      height = 32;
      indicator_height = 5;
    };
  };

  # Layer rules for better performance
  layerrule = [
    "noanim, walker"  # Disable animations for Walker launcher
  ];

}
