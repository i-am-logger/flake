{ pkgs, ... }:

{
  home.packages = with pkgs; [
    waybar
    fftw # cava
    iniparser # cava
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    blueman
    papirus-icon-theme # additional icon theme for better compatibility
    adwaita-icon-theme
  ];

  xdg.configFile."waybar/" = {
    source = ./config;
    recursive = true;
  };

  # Home-manager waybar config
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    })
  ];
}
