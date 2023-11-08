{ pkgs, ... }:
let
  image_url = "https://www.pixelstalk.net/wp-content/uploads/2016/07/Desktop-autumn-hd-wallpaper-3D.jpg";

  inputImage = pkgs.fetchurl {
    url = image_url;
    sha256 = "sha256-AIT4q35wpsTslkBnqFLlNiRtn6b7vaL6fvb14oqEv6I=";
  };
  #brightness = -30;
  #contrast = 0;
  #fillColor = "black";
in
{
  stylix = {
    polarity = "dark";

    opacity = {
      applications = 1.0; # 0.8;
      desktop = 1.0; # 0.8;
      popups = 1.0;
      terminal = 0.8;
    };
    image = inputImage;
    #pkgs.runCommand "dimmed-background.png" {} ''
    #  ${pkgs.imagemagick}/bin/convert "${inputImage}" -brightness-contrast ${brightness},${contrast} -fill ${fillColor} $out
    #'';
    #    image = pkgs.runCommand "Wallpapers/51202857906_363ba5d644_o.jpg" { } ''
    #      ${pkgs.imagemagick}/bin/convert ${ Wallpapers/51202857906_363ba5d644_o.jpg } -brightness-contrast -30,0 -fill black $out
    #    '';

    #    image = pkgs.runCommand "Wallpapers/51202857906_363ba5d644_o.jpg" { } ''
    #      ${pkgs.imagemagick}/bin/convert ${ Wallpapers/51202857906_363ba5d644_o.jpg } -brightness-contrast -30,0 -fill black $out
    #    '';

    base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    # base16Scheme = ./mission-control.yaml;

    targets.console.enable = false;
    targets.grub = {
      enable = false;
      #  useImage = false;
    };

    fonts = {
      sizes = {
        applications = 12;
        desktop = 12;
        popups = 12;
        terminal = 20;
      };
      serif = {
        # package = pkgs.noto-fonts;
        # name = "Noto Serif";

        package = pkgs.fira-code;
        name = "Fira Serif";
      };

      sansSerif = {
        #package = pkgs.noto-fonts;
        #name = "Noto Sans Mono";

        package = pkgs.fira-code;
        name = "Fira Sans";

        # package = pkgs.nerdfonts;
        # name = "FiraCode Nerd Font";
      };

      monospace = {
        package = pkgs.nerdfonts;
        name = "FiraCode Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";

        # package = pkgs.twitter-color-emoji;
        # name = "Twitter Color Emoji";
      };
    };
  };
}
