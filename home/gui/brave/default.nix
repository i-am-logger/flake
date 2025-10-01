{ pkgs, ... }:
let
  # Wrap Brave to use gnome-libsecret (which works with pass-secret-service)
  brave-with-keyring = pkgs.symlinkJoin {
    name = "brave-with-keyring";
    paths = [ pkgs.brave ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/brave \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
{
  # Copy the SkySpy wallpaper to a location Brave can access
  home.file.".local/share/skyspy/skyspy-wallpaper.png" = {
    source = ../../../Themes/Wallpapers/skyspy-wallpaper-2560x1600.png;
  };

  # Install Brave with YubiKey keyring support
  home.packages = [
    brave-with-keyring
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
