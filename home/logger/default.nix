{ lib, ... }:

{
  disabledModules = [ ];

  manual.manpages.enable = true;

  programs = {
    home-manager.enable = true;
    bash.enable = true;
    zellij.enable = true;
    fzf.enable = true;
  };

  home = {
    username = "logger";
    homeDirectory = "/home/logger";
    stateVersion = "25.11";
  };

  # Qt configuration
  qt = {
    enable = lib.mkForce false;
    platformTheme = lib.mkDefault { name = "gtk"; };
    style = lib.mkDefault { name = null; };
  };

  imports = [
    ../common.nix
    ./yubikey.nix
    ./jujutsu.nix
    ./git.nix
    ./ssh.nix
    # ./webapps.nix  # Disabled temporarily - chromium dependency build issues
    ../gui/brave
  ];
}
