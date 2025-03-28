{ config, pkgs, impermanence, ... }:
{
  imports = [
    impermanence.nixosModules.impermanence
  ];

  fileSystems."/persist" = {
    neededForBoot = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
      "/var/lib/gnome"
      "/var/lib/AccountsService"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/colord"
      "/var/lib/power-profiles-daemon"
      "/var/lib/upower"
    ];
    users.logger = {
      directories = [
        ".ssh"      # SSH keys and config
        ".local"
        ".cache"
        ".config"
        ".flake"    # NixOS configuration
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "Code"
        "Current-Rice"
        # ".local/share/warp-terminal"      # Warp Terminal data
        # ".mozilla"      # Firefox data
        # ".local/share/keyrings"
        # ".local/share/secrets"            # Secret storage
      ];
    };
  };
}

