{ pkgs, ... }:
let
  cursor = pkgs.callPackage ./cursor.nix { };
in
{
  imports = [
    ./xdg.nix
    cli/bat.nix
    # cli/direnv.nix
    cli/git.nix
    cli/lsd.nix
    cli/variables.nix
    # cli/neovim.nix
    # cli/tmux.nix

    cli/fish
    cli/starship
    cli/btop
    # cli/neofetch
    # cli/ranger
    cli/mc
    cli/helix
    cli/zellij.nix
    cli/cava
    # GUI
    gui/hyprland
    gui/rio
    gui/kitty
    # gui/ags
    # gui/rofi
    # gui/emacs/doom-emacs.nix
    # gui/chats/discord
    gui/obs-studio.nix
    #(../GUI/SDR)
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  home.packages = with pkgs; [
    # file manager
    yazi
    fastfetch
    # termscp
    # (import packages/qspectrumanalyzer.nix { inherit pkgs; })
    # ueberzug # move to yazi
    #ranger
    # IDE
    #lapce
    # calendar
    #calcurse
    # Web Browsers
    #qutebrowser
    firefox
    google-chrome
    brave
    # UI Virtual Terminals
    alacritty
    #kate
    neo
    pipes
    # UI Media Keys
    #playerctl
    #UI Apps
    # mypaint
    marktext
    #gimp
    #pfetch # Minimal fetch
    #github-desktop
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
    krusader # dual file browser GUI
    rpi-imager # Raspberri pi USB Imager
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
    signal-desktop
    # tdesktop # telegram
    tldr
    # development
    cachix
    # broadcasting
    #screenkey

    # astronomy
    #kstars
    # indi-full

    # coding
    # jetbrains.rust-rover
    # vscode
    # cursor
    bazecor
    cointop
    #pamixer
  ];
}
