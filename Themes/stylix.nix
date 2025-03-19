{ pkgs, ... }:
# let
# image_url = "https://www.pixelstalk.net/wp-content/uploads/2016/07/Desktop-autumn-hd-wallpaper-3D.jpg";

#   # inputImage = pkgs.fetchurl {
#   #   url = image_url;
#   #   sha256 = "sha256-AIT4q35wpsTslkBnqFLlNiRtn6b7vaL6fvb14oqEv6I=";
#   # };
#   #brightness = -30;
#   #contrast = 0;
#   #fillColor = "black";
# in
{
  imports = [
    ./ls-colors.nix
  ];

  stylix = {
    enable = true;
    polarity = "dark";
    ls-colors.enable = true;

    opacity = {
      applications = 0.8;
      desktop = 0.8;
      popups = 0.8;
      terminal = 0.8;
    };
    image = Wallpapers/futuristic3.jpg; # inputImage;

    # base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal-khold.yaml";
    base16Scheme = ./mission_hacker2.yaml;
    # base16Scheme = ./mission_hacker_dark.yaml;
    # base16Scheme = ./example.yaml;

    # targets.waybar.enable = false;
    targets.grub = {
      # enable = false;
      # useImage = false;
    };

    fonts = {
      sizes = {
        applications = 18;
        desktop = 18;
        popups = 18;
        terminal = 18;
      };
      serif = {
        name = "Noto Nerd Font";
        # name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.noto;
      };

      sansSerif = {
        # name = "Noto Nerd Font";
        name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.fira-code;
      };

      monospace = {
        name = "FiraCode Nerd Font";
        package = pkgs.nerd-fonts.fira-code;
      };

      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-emoji;

        # package = p:gs.twitter-color-emoji;
        # name = "Twitter Color Emoji";
      };
    };

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };
}
