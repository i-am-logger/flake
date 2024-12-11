{ pkgs
, username
, ...
}:
{
  environment.systemPackages = with pkgs; [
    docker-compose
    minikube
    runc
    # helm
    nvidia-docker
    lazydocker
  ];

  hardware.nvidia-container-toolkit.enable = true;
  users.groups.docker.members = [ "${username}" ];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    # enableNvidia = true;
    # rootless = {
    #   enable = true;
    #   # setSocketVariable = true;
    #   daemon.settings = {
    #     runtimes = {
    #       nvidia = {
    #         path = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
    #       };
    #     };
    #   };
    # };
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];
  # networking.firewall.allowedUDPPorts = [
  # ];
  # services.k3s.enable = true;
  # services.k3s.role = "server";
  # services.k3s.extraFlags = toString [
  #   # "--debug" # Optionally add additional args to k3s
  # ];
}
