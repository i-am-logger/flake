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
    ];
    users.logger = {
      directories = [
        ".ssh"      # SSH keys and config
        ".flake"    # NixOS configuration
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
        "Code"
        "Current-Rice"
      ];
    };
  };
}

