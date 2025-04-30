{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    docker-compose
    minikube
    runc
    lazydocker
  ];

  users.groups.docker.members = [
    "logger"
    "snick"
  ];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      data-root = "/var/lib/docker";
    };
  };

  # environment.persistence."/persist" = {
  #   directories = [ "/var/lib/docker " ];
  #   users.logger = {
  #     directories = [
  #       ".local/share/docker"
  #     ];
  #   };
  # };
  # networking.firewall.allowedTCPPorts = [
  #   6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  # ];
  # networking.firewall.allowedUDPPorts = [
  # ];
}
