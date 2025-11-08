{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    eww
    pamixer
    networkmanager
    coreutils
    procps
    curl
    gnugrep
    gawk
    cava
    hyprland
    grim
    wlr-randr
    slurp
    # For scripts
    pulseaudio # pactl for volume-deflisten
    jq # JSON processing for get-workspaces
    socat # Socket communication for workspace monitoring
    util-linux # date command
    bash # Bash shell for scripts
    # Fonts
    nerd-fonts.fira-code # FiraCode Nerd Font to match stylix
  ];

  shellHook = ''
    echo "Eww testing environment ready!"
    echo "Run 'eww open bar' to start the bar"
    echo "Run 'eww close bar' to close it"
  '';
}
