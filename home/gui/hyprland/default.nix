{ pkgs, ... }: {
  imports = [
    ./waybar
    ./swappy
    # ./pyprland
  ];

  home.pointerCursor = {
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    # iconTheme = {
    # package = pkgs.gnome.adwaita-icon-theme;
    # name = "Adwaita";
    # };
  };
  # services.blueman.enable = true;
  services.blueman-applet.enable = true;

  home.packages = with pkgs; [
    # pkgs.xorg.xprop # trying to fix scale of non hyprland windows like signal, discord
    #hyprland
    libinput
    wlr-randr
    mako
    pipewire
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    brightnessctl
    #wallpaper
    swww
    waypaper
    swaybg
    # screenshot
    grimblast
    slurp
    swappy
    # clipboard
    wl-clipboard
    cliphist
    # mount
    udiskie
    #video player
    vlc
    #   polkit-kde-agent #TODO: configure and get rid of gnome dekstop manager
    #libsForQt5.full -- error of insecure
    # pkgs.qt6.full
    # pkgs.qt-wayland
    # pkgs.wineWowPackages.waylandFull
    # pkgs.winetricks
    hyprpicker

    hyprpaper
    swaylock-effects
    wlogout
    networkmanagerapplet

    pavucontrol
    pamixer
    playerctl

    gtk3
  ];

  xdg.configFile."hypr" = {
    source = ./config;
    recursive = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
  };
}
