{ pkgs, ... }: {
  imports = [
    ./waybar
    ./swappy
    ./pyprland
  ];

  # home.pointerCursor = {
  # gtk.enable = true;
  # x11.enable = true;
  # package = pkgs.bibata-cursors;
  # name = "Bibata-Modern-Ice";
  # size = 12;
  # };
  # services.blueman.enable = true;
  services.blueman-applet.enable = true;

  home.packages = [
    pkgs.xorg.xprop # trying to fix scale of non hyprland windows like signal, discord

    #hyprland
    pkgs.wlr-randr
    pkgs.mako
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.xdg-desktop-portal-hyprland

    #wallpaper
    pkgs.swww
    pkgs.swaybg
    # screenshot
    pkgs.grimblast
    pkgs.slurp
    pkgs.swappy
    # clipboard
    pkgs.wl-clipboard
    pkgs.cliphist
    # mount
    pkgs.udiskie
    #video player
    pkgs.vlc
    #   polkit-kde-agent #TODO: configure and get rid of gnome dekstop manager
    #libsForQt5.full -- error of insecure
    # pkgs.qt6.full
    # pkgs.qt-wayland
    pkgs.wineWowPackages.waylandFull
    pkgs.winetricks
    pkgs.hyprpicker


    pkgs.pavucontrol
    pkgs.pamixer
    pkgs.playerctl
  ];

  xdg.configFile."hypr" = {
    source = ./config;
    recursive = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    # settings = {
    #   general = {
    #     layout = "dwindle";
    #   };
    # };

    xwayland = {
      enable = true;
    };
  };
}
