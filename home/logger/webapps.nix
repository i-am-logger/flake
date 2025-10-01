{ pkgs, ... }:

{
  # Install icon theme packages for webapp icons
  home.packages = with pkgs; [
    papirus-icon-theme  # Best webapp icon coverage
    adwaita-icon-theme  # GNOME default icons
  ];

  programs.webApps = {
    enable = true;
    
    # Let it auto-detect browser from your programs.brave configuration
    # browser = pkgs.chromium;  # or specify explicitly if needed
    
    apps = {
      gmail = {
        url = "https://mail.google.com";
        name = "Gmail";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/gmail.svg";
        categories = [ "Network" "Email" "Office" ];
        mimeTypes = [ "x-scheme-handler/mailto" ];
        startupWmClass = "gmail-webapp";
      };
    };
  };
}