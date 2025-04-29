{
  config,
  pkgs,
  impermanence,
  ...
}:
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
        ".local"
        ".cache"
        ".config"
        ".flake" # NixOS configuration
        ".secrets"
        # "Desktop"
        "Documents"
        "Downloads"
        "Media"
        # "Music"
        # "Pictures"
        # "Videos"
        "Code"
        "Current-Rice"
        ".mozilla" # Firefox data
      ];
      files = [
        ".bash_history"
        "/etc/nixos"
      ];
    };
  };
}
