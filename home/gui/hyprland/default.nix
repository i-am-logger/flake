{ pkgs, inputs, ... }:
{
    imports = [
    (./waybar)
    (./swappy)
    ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 22;
  };
  #services.blueman.enable = true;
  services.blueman-applet.enable  = true;

#  nixpkgs.overlays = [ (final: prev: {
#    xdg-desktop-portal-hyprland = inputs.xdph.packages.${prev.system}.default.override {
#      hyprland-share-picker = inputs.nixos-hardware.packages.${prev.system}.hyprland-share-picker.override {inherit hyprland;};
#    };
#  })];
  
  home.packages = with pkgs ; [

    xorg.xprop # trying to fix scale of non hyprland windows like signal, discord
    
    #hyprland
     wlr-randr
     mako
     pipewire
     wireplumber
     xdg-desktop-portal-hyprland

    #wallpaper
    swww
    swaybg    
    # screenshot
    grim
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
     qt6.full
     wineWowPackages.waylandFull
     winetricks
     hyprpicker
     inputs.hypr-contrib.packages.${pkgs.system}.grimblast    
     inputs.hypr-contrib.packages.${pkgs.system}.scratchpad 
  ];


  xdg.configFile."hypr" = {
    source = ./config;
    recursive = true;
  };
  
  wayland.windowManager.hyprland = {
    enable = true;
    #nvidiaPatches = true;

    xwayland = {
      enable = true;
      hidpi = true;
    };
  };    
}
