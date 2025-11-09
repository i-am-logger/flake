{ config
, pkgs
, lib
, ...
}:

let
  # List of repositories to create runner sets for
  repositories = [
    "flake"
    "loial"
    "logger"
    "pds"
  ];

  githubUsername = "i-am-logger";
  hostname = config.networking.hostName;

  # Generate runner set services for each repository
  mkRunnerSetService = repo: {
    name = "arc-runner-set-${repo}";
    value = {
      description = "Deploy GitHub Actions Runner Scale Set for ${repo}";
      after = [ "arc-setup.service" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionPathExists = "!/var/lib/arc-runner-set-${repo}-done";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = "/persist/etc/github-runner-token";
      };

      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Wait for ARC controller
        until ${pkgs.kubectl}/bin/kubectl get namespace arc-systems; do
          echo "Waiting for ARC controller..."
          sleep 5
        done

        # Additional wait for controller to be fully ready
        sleep 10

        if [ -z "$GITHUB_TOKEN" ]; then
          echo "Error: GITHUB_TOKEN not found in environment file"
          exit 1
        fi

        # Install runner scale set for ${repo} with hostname in name
        ${pkgs.kubernetes-helm}/bin/helm upgrade --install arc-runner-set-${repo} \
          --namespace arc-runners \
          --create-namespace \
          --set githubConfigUrl="https://github.com/${githubUsername}/${repo}" \
          --set githubConfigSecret.github_token="$GITHUB_TOKEN" \
          --set runnerScaleSetName="${hostname}-${repo}" \
          oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

        touch /var/lib/arc-runner-set-${repo}-done
        echo "Runner scale set for ${repo} deployed successfully"
      '';
    };
  };
in
{
  # Enable k3s Kubernetes
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"
    ];
  };

  # Install required packages
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k3s
    git
    jq
  ];

  # Set KUBECONFIG environment variable system-wide
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  # Open k3s API port
  networking.firewall.allowedTCPPorts = [ 6443 ];

  # Create GitHub token environment file from gh CLI
  # This runs once at activation to populate the token file
  system.activationScripts.createGithubRunnerToken = {
    text = ''
            if [ ! -f /persist/etc/github-runner-token ]; then
              echo "Creating GitHub runner token file..."
              mkdir -p /persist/etc
              
              # Try to get token from gh CLI (run as logger user)
              if ${pkgs.sudo}/bin/sudo -u logger ${pkgs.gh}/bin/gh auth status &>/dev/null; then
                GITHUB_TOKEN=$(${pkgs.sudo}/bin/sudo -u logger ${pkgs.gh}/bin/gh auth token)
                cat > /persist/etc/github-runner-token << EOF
      GITHUB_TOKEN=$GITHUB_TOKEN
      GITHUB_USERNAME=i-am-logger
      EOF
                chmod 600 /persist/etc/github-runner-token
                chown root:root /persist/etc/github-runner-token
                echo "GitHub runner token file created"
              else
                echo "WARNING: gh CLI not authenticated. Please run 'gh auth login' as logger user."
                echo "Then run: sudo nixos-rebuild switch"
              fi
            fi
    '';
    deps = [
      "users"
      "groups"
    ];
  };

  # Setup ARC controller after k3s is ready and deploy runner scale sets
  systemd.services = lib.listToAttrs (map mkRunnerSetService repositories) // {
    # Make kubeconfig readable by users
    k3s-kubeconfig-permissions = {
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
    arc-setup = {
      description = "Setup GitHub Actions Runner Controller";
      after = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];

      unitConfig = {
        ConditionPathExists = "!/var/lib/arc-setup-done";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Wait for k3s to be ready
        until ${pkgs.k3s}/bin/kubectl get nodes; do
          echo "Waiting for k3s..."
          sleep 5
        done

        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        # Install cert-manager (required for ARC)
        ${pkgs.kubectl}/bin/kubectl apply -f \
          https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

        # Wait for cert-manager
        echo "Waiting for cert-manager to be ready..."
        sleep 30

        # Add ARC helm repo
        ${pkgs.kubernetes-helm}/bin/helm repo add actions-runner-controller \
          https://actions-runner-controller.github.io/actions-runner-controller

        ${pkgs.kubernetes-helm}/bin/helm repo update

        # Install ARC controller
        ${pkgs.kubernetes-helm}/bin/helm upgrade --install arc \
          --namespace arc-systems \
          --create-namespace \
          oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

        touch /var/lib/arc-setup-done
        echo "ARC controller installed successfully"
      '';
    };
  };
}
