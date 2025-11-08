{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.stacks.cicd;
  # List of repositories to create runner sets for
  repositories = [
    "flake"
    "loial"
    "logger"
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
      
      # unitConfig = {
      #   ConditionPathExists = "!/var/lib/arc-runner-set-${repo}-done";
      # };

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
        # Using dind mode with proper configuration
        ${pkgs.kubernetes-helm}/bin/helm upgrade --install arc-runner-set-${repo} \
          --namespace arc-runners \
          --create-namespace \
          --set githubConfigUrl="https://github.com/${githubUsername}/${repo}" \
          --set githubConfigSecret.github_token="$GITHUB_TOKEN" \
          --set runnerScaleSetName="host-${hostname}-repo-${repo}" \
          --set minRunners=0 \
          --set maxRunners=5 \
          --set runnerGroup="Default" \
          --set containerMode.type="dind" \
          oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

        touch /var/lib/arc-runner-set-${repo}-done
        echo "Runner scale set for ${repo} deployed successfully"
      '';
    };
  };
in
{
  options.stacks.cicd = {
    enable = mkEnableOption "CI/CD stack (GitHub Actions Runners + k3s)";
    
    repositories = mkOption {
      type = types.listOf types.str;
      default = repositories;
      description = "List of repositories to create runner sets for";
    };
    
    githubUsername = mkOption {
      type = types.str;
      default = "i-am-logger";
      description = "GitHub username for runner authentication";
    };
    
    enableGpu = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GPU passthrough to runners (requires GPU device plugin)";
    };
    
    gpuVendor = mkOption {
      type = types.enum [
        "amd"
        "nvidia"
      ];
      default = "amd";
      description = "GPU vendor for device plugin (amd or nvidia)";
    };
  };

  config = mkIf cfg.enable {
    # Enable k3s via Infra service
    infra.services.k3s = {
      enable = true;
      role = "server";
      disableTraefik = true;
      kubeconfigReadable = true;
    };

    # Install additional packages for GitHub Actions
    environment.systemPackages = with pkgs; [
      git
      jq
    ];

  # Create GitHub token environment file from pass
  # This runs once at activation to populate the token file
  # To set the token: pass insert github/runner-pat
  system.activationScripts.createGithubRunnerToken = {
    text = ''
      if [ ! -f /persist/etc/github-runner-token ]; then
        echo "Creating GitHub runner token file..."
        mkdir -p /persist/etc
        
        # Try to get PAT from pass (run as logger user)
        if ${pkgs.sudo}/bin/sudo -u logger ${pkgs.pass}/bin/pass show github/runner-pat &>/dev/null; then
          GITHUB_TOKEN=$(${pkgs.sudo}/bin/sudo -u logger ${pkgs.pass}/bin/pass show github/runner-pat)
          cat > /persist/etc/github-runner-token << EOF
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_USERNAME=i-am-logger
EOF
          chmod 600 /persist/etc/github-runner-token
          chown root:root /persist/etc/github-runner-token
          echo "GitHub runner token file created from pass"
        else
          echo "WARNING: GitHub PAT not found in pass at github/runner-pat"
          echo "Please run: pass insert github/runner-pat"
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

        ${optionalString cfg.enableGpu (
          if cfg.gpuVendor == "amd" then ''
        # Install AMD GPU device plugin
        echo "Installing AMD GPU device plugin..."
        ${pkgs.kubectl}/bin/kubectl apply -f https://raw.githubusercontent.com/ROCm/k8s-device-plugin/master/k8s-ds-amdgpu-dp.yaml
        
        # Wait for device plugin to be ready
        echo "Waiting for GPU device plugin..."
        sleep 10
        '' else ''
        # Install NVIDIA GPU device plugin
        echo "Installing NVIDIA GPU device plugin..."
        ${pkgs.kubectl}/bin/kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.15.0/deployments/static/nvidia-device-plugin.yml
        
        # Wait for device plugin to be ready
        echo "Waiting for GPU device plugin..."
        sleep 10
        ''
        )}

        touch /var/lib/arc-setup-done
        echo "ARC controller installed successfully"
      '';
    };
  };
  };
}
