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
  stylix = {
    enable = true;
    polarity = "dark";

    opacity = {
      applications = 0.8;
      desktop = 0.8;
      popups = 0.8;
      terminal = 0.8;
    };
    # image = Wallpapers/51202857906_363ba5d644_o.jpg; #inputImage;
    image = Wallpapers/futuristic1.png; #inputImage;
    # pkgs.runCommand "dimmed-background.png" {} ''
    #   ${pkgs.imagemagick}/bin/convert "${inputImage}" -brightness-contrast ${brightness},${contrast} -fill ${fillColor} $out
    # '';
    # image = pkgs.runCommand "Wallpapers/51202857906_363ba5d644_o.jpg" { } ''
    #   ${pkgs.imagemagick}/bin/convert ${ Wallpapers/51202857906_363ba5d644_o.jpg } -brightness-contrast -30,0 -fill black $out
    # '';

    #    image = pkgs.runCommand "Wallpapers/51202857906_363ba5d644_o.jpg" { } ''
    #      ${pkgs.imagemagick}/bin/convert ${ Wallpapers/51202857906_363ba5d644_o.jpg } -brightness-contrast -30,0 -fill black $out
    #    '';

    # base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    base16Scheme = ./mission_hacker.yaml;
    # base16Scheme = ./example.yaml;

    # targets.console.enable = false;
    # targets.waybar.enable = false;
    targets.grub = {
      enable = false;
      # useImage = false;
    };

    fonts = {
      sizes = {
        applications = 12;
        desktop = 12;
        popups = 12;
        terminal = 14;
      };
      serif = {
        name = "Noto Nerd Font";
        # name = "FiraCode Nerd Font";
        package = pkgs.nerdfonts;
      };

      sansSerif = {
        name = "Noto Nerd Font";
        # name = "FiraCode Nerd Font";
        package = pkgs.nerdfonts;
      };

      monospace = {
        name = "FiraCode Nerd Font";
        package = pkgs.nerdfonts;
      };

      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-emoji;

        # package = p:gs.twitter-color-emoji;
        # name = "Twitter Color Emoji";
      };
    };
  };
}
