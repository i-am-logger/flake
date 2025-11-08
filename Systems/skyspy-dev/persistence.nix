{ config
, pkgs
, impermanence
, ...
}:
{
  imports = [
    impermanence.nixosModules.impermanence
  ];

  # Create /persist directory on existing filesystem
  # No separate partition needed - uses existing disk
  systemd.tmpfiles.rules = [
    "d /persist 0755 root root -"
    "d /persist/home 0755 root root -"
    "d /persist/home/logger 0755 logger users -"
  ];

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
      # Nvidia-specific directories
      "/var/lib/nvidia-persistenced"
      {
        directory = "/var/lib/ollama";
        user = "ollama";
        group = "ollama";
        mode = "0755";
      }
      # Development-specific directories
      "/var/lib/docker" # Docker data
      "/var/lib/containers" # Container data
      "/yubikey" # YubiKey system configuration
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
        "GitHub"
        "Current-Rice"
        ".mozilla" # Firefox data
        # Development directories
        ".docker" # Docker config
        ".npm" # npm cache
        ".cargo" # Rust cargo
        ".rustup" # Rust toolchain
        ".gradle" # Gradle cache
        ".m2" # Maven cache
        ".vscode" # VS Code settings
        # YubiKey and GPG directories
        ".gnupg" # GPG keys and configuration
        ".password-store" # Pass password store for secret service
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
