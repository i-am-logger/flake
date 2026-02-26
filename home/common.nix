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
    gui/niri
    # gui/ghostty
    gui/wezterm
    gui/obs-studio.nix
    # gui/streamdeck.nix
    gui/walker
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  nixpkgs.overlays = [
    (import ../overlays/claude-code.nix)
  ];

  home.packages = with pkgs; [
    # file manager
    yazi
    mc
    fastfetch
    devenv
    termscp
    tmux
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
    # brave # Now provided by custom wrapper in gui/brave
    # UI Virtual Terminals
    alacritty
    #kate
    neo
    pipes
    # UI Media Keys
    #playerctl
    #UI Apps
    mypaint
    #marktext # broken: node-gyp not found during build
    #gimp
    #pfetch # Minimal fetch
    claude-code
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

    # Audio control
    pavucontrol # PulseAudio volume control
    pipewire # Includes wpctl command
    pamixer # Command-line audio mixer
    kdiff3
    rclone
    # insync

    # screensaver
    asciiquarium
    #expect # has unbuffer - helpful with watch like - watch --color --interval 1 unbuffer lsd --tree
    #jq
    # Music
    audacious
    # spotify # Does not support Secret Service API (proprietary client) - Replaced with webapp
    musikcube
    # unityhub
    # spotify-tui
    # spotifyd

    # Chats
    # qtox
    # signal-desktop is now provided by common/electron-apps.nix
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
  ];
}
