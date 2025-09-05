{ pkgs, ... }:
{
  # Copy the SkySpy wallpaper to a location Brave can access
  home.file.".local/share/skyspy/skyspy-wallpaper.png" = {
    source = ../../../Themes/Wallpapers/skyspy-wallpaper-2560x1600.png;
  };

  # Install Brave browser normally  
  home.packages = with pkgs; [
    brave
  ];

  # Configure XDG for Brave
  xdg.desktopEntries.brave-browser = {
    name = "Brave Browser";
    comment = "Brave browser";
    exec = "brave %U";
    icon = "brave-browser";
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };
}
