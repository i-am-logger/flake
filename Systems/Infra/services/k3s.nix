{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.infra.services.k3s;
in
{
  options.infra.services.k3s = {
    enable = mkEnableOption "k3s Kubernetes cluster";
    
    role = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "server";
      description = "k3s role - server or agent";
    };
    
    disableTraefik = mkOption {
      type = types.bool;
      default = true;
      description = "Disable built-in Traefik ingress controller";
    };
    
    apiPort = mkOption {
      type = types.port;
      default = 6443;
      description = "k3s API server port";
    };
    
    kubeconfigReadable = mkOption {
      type = types.bool;
      default = true;
      description = "Make kubeconfig readable by non-root users";
    };
  };

  config = mkIf cfg.enable {
    # Enable k3s
    services.k3s = {
      enable = true;
      role = cfg.role;
      extraFlags = toString (
        optionals cfg.disableTraefik [ "--disable=traefik" ]
      );
    };

    # Install essential k8s tools
    environment.systemPackages = with pkgs; [
      kubectl
      kubernetes-helm
      k3s
    ];

    # Set KUBECONFIG environment variable system-wide
    environment.variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };

    # Open API port and trust k3s network interfaces
    networking.firewall = {
      allowedTCPPorts = [ cfg.apiPort ];
      trustedInterfaces = [ "cni0" "flannel.1" ];
    };

    # Make kubeconfig readable by users
    systemd.services.k3s-kubeconfig-permissions = mkIf cfg.kubeconfigReadable {
      description = "Set k3s kubeconfig permissions";
      after = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
          sleep 1
        done
        chmod 644 /etc/rancher/k3s/k3s.yaml
      '';
    };

    # Prevent NetworkManager from managing k3s interfaces
    environment.etc."NetworkManager/conf.d/k3s-unmanaged.conf".text = ''
      [keyfile]
      unmanaged-devices=interface-name:cni*;interface-name:flannel*;interface-name:veth*
    '';
  };
}
