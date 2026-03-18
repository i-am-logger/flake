{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasNvidia = config.hardware.nvidia.modesetting.enable or false;
  hasAmd = builtins.elem "amdgpu" (config.services.xserver.videoDrivers or [ ]);
  acceleration = if hasNvidia then "cuda" else if hasAmd then "rocm" else false;
  isRocm = acceleration == "rocm";
in
{
  options.local.ollama.models = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Models to auto-pull on service start";
  };

  config = {
    # Define ollama user and group explicitly
    users.users.ollama = {
      isSystemUser = true;
      group = "ollama";
      home = "/var/lib/ollama";
      uid = 988;
      extraGroups = [
        "render"
        "video"
      ];
    };

    users.groups.ollama = {
      gid = 983;
    };

    # Ensure ollama directories exist with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/ollama 0755 ollama ollama -"
      "d /var/lib/ollama/models 0755 ollama ollama -"
    ];

    # ROCm packages only when AMD GPU detected
    environment.systemPackages = lib.mkIf isRocm (
      with pkgs;
      [
        rocmPackages.rocm-runtime
        rocmPackages.rocm-device-libs
        rocmPackages.rocm-smi
        rocmPackages.hipify
      ]
    );

    environment.variables = lib.mkMerge [
      {
        # Shared memory optimizations
        OLLAMA_HOST = "127.0.0.1:11434";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_FLASH_ATTENTION = "true";
      }
      (lib.mkIf isRocm {
        ROC_ENABLE_PRE_VEGA = "1";
        HSA_OVERRIDE_GFX_VERSION = "11.0.2";
      })
    ];

    services.ollama = {
      enable = true;
      # Package determines GPU backend: ollama-cuda for NVIDIA, ollama-rocm for AMD, ollama for CPU
      package =
        if hasNvidia then
          pkgs.ollama-cuda
        else if isRocm then
          pkgs.ollama-rocm
        else
          pkgs.ollama;

      user = "ollama";
      group = "ollama";

      home = "/var/lib/ollama";
      models = "/var/lib/ollama/models";

      loadModels = config.local.ollama.models;
    };

    # Override the systemd service to disable DynamicUser
    systemd.services.ollama = {
      serviceConfig = {
        DynamicUser = lib.mkForce false;
      };
      environment = lib.mkIf isRocm {
        HSA_OVERRIDE_GFX_VERSION = "11.0.2";
        ROC_ENABLE_PRE_VEGA = "1";
      };
    };

    services.nextjs-ollama-llm-ui.enable = true;

    # Ollama models directory is now persisted via impermanence in persistence.nix
  };
}
