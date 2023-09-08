{ pkgs, pkgs-stable, ... }: {
  imports = [
    ./xdg.nix
    #../Programs/PasswordManagers/1Password)
    cli/bat.nix
    cli/direnv.nix
    #cli/exa.nix
    cli/git.nix
    cli/lsd.nix
    cli/variables.nix

    cli/fish
    cli/btop
    cli/neofetch
    cli/ranger
    cli/mc
    cli/helix
    cli/cava

    # GUI
    gui/hyprland
    gui/kitty
    gui/chats/discord
    #../GUI/obs-studio.nix
    #(../GUI/SDR)
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  home.packages = with pkgs; [
    # file manager
    #ranger
    # IDE
    #lapce
    # calendar
    #calcurse
    # Web Browsers
    #qutebrowser
    firefox
    #google-chrome
    # UI Virtual Terminals
    #alacritty
    #kate
    neo

    # UI Media Keys
    #playerctl
    #UI Apps
    mypaint
    #gimp
    #pfetch # Minimal fetch
    #github-desktop
    # Video/Audio
    #cli-visualizer # Audio visualizer
    #feh # Image Viewer
    #sxiv # Image Viewer
    #mpv # Media Player
    #pavucontrol # Audio control
    #plex-media-player # Media Player
    #vlc # Media Player
    #stremio        # Media Streamer
    #ffmpeg # Video Support (dslr)
    #libGL
    #rofi # Menu
    #udiskie # Auto Mounting
    rpi-imager # Raspberri pi USB Imager
    # screensaver

    #expect # has unbuffer - helpful with watch like - watch --color --interval 1 unbuffer lsd --tree
    #jq
    # Music
    #spotify
    #spotify-tui
    #spotifyd

    # Chats
    qtox
    signal-desktop
    tdesktop # telegram

    # broadcasting
    #screenkey

    # astronomy
    #kstars
    #indi-full

    # coding
    #vscode

    # sky360
    #libusb1
    #fxload

    #pamixer
  ];
}
