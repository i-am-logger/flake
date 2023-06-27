{ stylix, pkgs, ... }:

{
  stylix = {

    targets.console.enable = false;
    
    polarity = "dark";

    opacity = {
      applications = 0.8;
      desktop = 1.0;
      popups = 1.0;
      terminal = 0.8;      
    };

    image = pkgs.runCommand "Wallpapers/51202857906_363ba5d644_o.jpg" { } ''
      ${pkgs.imagemagick}/bin/convert ${ Wallpapers/51202857906_363ba5d644_o.jpg } -brightness-contrast -30,0 -fill black $out
    '';
    base16Scheme = base16-schemes/tomorrow-night.yaml;
                
    targets.grub = {
      enable = false;
      useImage = false;
    };

    fonts = {

      sizes = {
        applications = 11;
        desktop = 11;
        popups = 11;
        terminal = 11;
      };
                  
      serif = {
        name = "Cantarell";
        package = pkgs.cantarell-fonts;
                    
        #package = pkgs.nerdfonts;
        #name = "New York Medium";
        #name = "FiraCode Nerd Font";
      };

      sansSerif = {
        package = pkgs.cantarell-fonts;
        name = "Cantarell";
                    
        #package = pkgs.nerdfonts;
        #name = "SF Pro Text";
        #name = "FiraCode Nerd Font";
      };

      monospace = {
        package = pkgs.nerdfonts;
        name = "FiraCode Nerd Font";
        #name = "LigaSF Mono Nerd Font";
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