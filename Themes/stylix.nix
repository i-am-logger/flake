{ pkgs, ... }:

# image_url = "https://www.pixelstalk.net/wp-content/uploads/2016/07/Desktop-autumn-hd-wallpaper-3D.jpg";

#   # inputImage = pkgs.fetchurl {
#   #   url = image_url;
#   #   sha256 = "sha256-AIT4q35wpsTslkBnqFLlNiRtn6b7vaL6fvb14oqEv6I=";
#   # };
#   #brightness = -30;
#   #contrast = 0;
#   #fillColor = "black";
{
  imports = [
    ./ls-colors.nix
  ];

  stylix = {
    enable = true;
    polarity = "dark";
    ls-colors.enable = true;

    opacity = {
      applications = 0.95;
      desktop = 0.95;
      popups = 0.95;
      terminal = 0.95;
    };
    image = Wallpapers/skyspy-wallpaper-2560x1600.png; # Custom wallpaper with logo centered

    # base16Scheme = "${pkgs.base16-schemes}/share/themes/black-metal-khold.yaml";
    base16Scheme = ./mission_hacker_white.yaml;
    # base16Scheme = ./mission_hacker_dark.yaml;
    # base16Scheme = ./example.yaml;

    # targets.waybar.enable = false;
    
    # Disable GRUB theming since we use systemd-boot
    targets.grub.enable = false;
    
    # Note: systemd-boot theming is handled automatically by Stylix
    # when available in the Stylix version

    fonts = {
      sizes = {
        applications = 28;
        desktop = 32;
        popups = 28;
        terminal = 32;
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
      name = "Bibata-Modern-Amber";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };
}
