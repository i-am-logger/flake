{ pkgs, ... }:
# let
# in
# cursor = pkgs.callPackage ./cursor.nix { };
{
  imports = [
    ./xdg.nix
    cli/bat.nix
    cli/direnv.nix
    cli/lsd.nix
    cli/variables.nix
    cli/nix-scripts.nix
    cli/starship
    cli/btop
    cli/mc
    cli/helix
    cli/zellij.nix
    cli/cava
    # GUI
    gui/hyprland
    gui/ghostty
    gui/wezterm
    gui/obs-studio.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  home.packages = with pkgs; [
    # file manager
    yazi
    mc
    fastfetch
    devenv
    termscp
    # (import packages/qspectrumanalyzer.nix { inherit pkgs; })
    # ueberzug # move to yazi
    #ranger
    # IDE
    #lapce
    # calendar
    #calcurse
    # Web Browsers
    #qutebrowser
    # firefox
    # google-chrome
    brave
    # UI Virtual Terminals
    alacritty
    #kate
    neo
    pipes
    # UI Media Keys
    #playerctl
    #UI Apps
    mypaint
    marktext
    #gimp
    #pfetch # Minimal fetch
    github-desktop
    # Video/Audio
    #cli-visualizer # Audio visualizer
    feh # Image Viewer
    #sxiv # Image Viewer
    #mpv # Media Player
    #pavucontrol # Audio control
    #plex-media-player # Media Player
    #vlc # Media Player
    #stremio        # Media Streamer
    #ffmpeg # Video Support (dslr)
    #libGL
    #udiskie # Auto Mounting
    # krusader # dual file browser GUI
    # rpi-imager # Raspberri pi USB Imager
    kdiff3
    krename
    rclone
    # insync

    # screensaver
    asciiquarium
    #expect # has unbuffer - helpful with watch like - watch --color --interval 1 unbuffer lsd --tree
    #jq
    # Music
    audacious
    spotify
    musikcube
    # unityhub
    # spotify-tui
    # spotifyd

    # Chats
    # qtox
    signal-desktop-bin
    # tdesktop # telegram
    # tldr
    # development
    # cachix
    # broadcasting
    wshowkeys # Wayland-compatible key display

    # astronomy
    #kstars
    # indi-full

    # coding
    # jetbrains.rust-rover
    # vscode
    # cursor
    # bazecor
    cointop
    #pamixer
  ];
}
