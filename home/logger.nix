{
  imports = [
    ./common.nix
    ./cli
    ./gui
  ];

  home = {
    username = "logger";
    homeDirectory = "/home/logger";
    stateVersion = "23.11"; # Use the current NixOS version
  };
}

