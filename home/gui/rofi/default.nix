{pkgs, ...}: {
  home.packages = with pkgs; [
    # rofi-wayland
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-calc
      rofi-emoji
      rofi-power-menu
      rofi-bluetooth
    ];
  };
}
