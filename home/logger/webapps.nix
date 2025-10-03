{ pkgs, ... }:
let
  # Create a chromium with Widevine enabled for webapps (needed for Spotify DRM)
  chromiumWithWidevine = pkgs.chromium.override {
    enableWideVine = true;
  };
in
{
  # Install icon theme packages for webapp icons
  home.packages = with pkgs; [
    papirus-icon-theme  # Best webapp icon coverage
    adwaita-icon-theme  # GNOME default icons
  ];

  programs.webApps = {
    enable = true;
    
    # Use chromium with Widevine enabled for DRM content like Spotify
    browser = chromiumWithWidevine;
    
    apps = {
      gmail = {
        url = "https://mail.google.com";
        name = "Gmail";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/gmail.svg";
        categories = [ "Network" "Email" "Office" ];
        mimeTypes = [ "x-scheme-handler/mailto" ];
        startupWmClass = "gmail-webapp";
      };
      
      # Electron app replacements
      vscode = {
        url = "https://vscode.dev";
        name = "VS Code";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/code.svg";
        categories = [ "Development" "TextEditor" ];
        startupWmClass = "vscode-webapp";
      };
      
      spotify = {
        url = "https://open.spotify.com";
        name = "Spotify";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/spotify.svg";
        categories = [ "Audio" "Music" "AudioVideo" ];
        startupWmClass = "spotify-webapp";
      };
      
      # Social and Development
      github = {
        url = "https://github.com";
        name = "GitHub";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/github-desktop.svg";
        categories = [ "Development" "Network" ];
        startupWmClass = "github-webapp";
      };
      
      discord = {
        url = "https://discord.com/app";
        name = "Discord";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/discord.svg";
        categories = [ "Network" "Chat" "Game" ];
        startupWmClass = "discord-webapp";
      };
      
      whatsapp = {
        url = "https://web.whatsapp.com";
        name = "WhatsApp";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/whatsapp.svg";
        categories = [ "Network" "Chat" "InstantMessaging" ];
        startupWmClass = "whatsapp-webapp";
      };
      
      # Media
      youtube = {
        url = "https://youtube.com";
        name = "YouTube";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/youtube.svg";
        categories = [ "AudioVideo" "Network" "Video" ];
        startupWmClass = "youtube-webapp";
      };
      
      netflix = {
        url = "https://netflix.com";
        name = "Netflix";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/netflix.svg";
        categories = [ "AudioVideo" "Video" "Network" ];
        startupWmClass = "netflix-webapp";
      };
      
      twitch = {
        url = "https://twitch.tv";
        name = "Twitch";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/twitch.svg";
        categories = [ "AudioVideo" "Video" "Network" "Game" ];
        startupWmClass = "twitch-webapp";
      };
      
      # Video Conferencing
      zoom = {
        url = "https://zoom.us/signin";
        name = "Zoom";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/zoom.svg";
        categories = [ "Network" "VideoConference" "Office" ];
        startupWmClass = "zoom-webapp";
      };
      
      # AI Assistants
      chatgpt = {
        url = "https://chat.openai.com";
        name = "ChatGPT";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/openai.svg";
        categories = [ "Network" "Office" "Education" ];
        startupWmClass = "chatgpt-webapp";
      };
      
      claude = {
        url = "https://claude.ai";
        name = "Claude";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/anthropic.svg";
        categories = [ "Network" "Office" "Education" ];
        startupWmClass = "claude-webapp";
      };
      
      grok = {
        url = "https://grok.com";
        name = "Grok";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/x.svg";
        categories = [ "Network" "Office" "Education" ];
        startupWmClass = "grok-webapp";
      };
      
      x = {
        url = "https://x.com";
        name = "X (Twitter)";
        icon = "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/twitter.svg";
        categories = [ "Network" "News" ];
        startupWmClass = "x-webapp";
      };
    };
  };
}