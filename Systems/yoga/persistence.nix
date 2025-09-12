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
      "/etc/nixos"
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
      {
        directory = "/var/lib/ollama";
        user = "ollama";
        group = "ollama";
        mode = "0755";
      }
    ];
    users.logger = {
      directories = [
        ".local"
        ".cache"
        ".config"
        # ".flake" # NixOS configuration
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
        # YubiKey and GPG directories
        ".gnupg" # GPG keys and configuration
        ".yubico" # YubiKey authorized keys
        ".ssh" # SSH keys
      ];
      files = [
        ".bash_history"
      ];
    };
  };

  system.activationScripts.cloneRepoIfEmpty = {
    text = ''
      if [ ! -e /etc/nixos ] || [ -z "$(ls -A /etc/nixos 2>/dev/null)" ]; then
        echo "Cloning flake repository into /etc/nixos..."
        mkdir -p /etc/nixos
        git clone git@github.com:i-am-logger/flake.git /etc/nixos
      fi
    '';
    deps = [
      "users"
      "groups"
    ];
  };

  system.activationScripts.createFlakeSymlink = {
    text = ''
      if [ ! -L /home/logger/.flake ]; then
        ln -sfn /etc/nixos /home/logger/.flake
      fi
    '';
    deps = [
      "users"
      "groups"
      "cloneRepoIfEmpty"
    ];
    # deps = [ "logger" ];
  };
}
