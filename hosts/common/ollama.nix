{ pkgs
, ...
}:

{
  # Define ollama user and group explicitly
  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    home = "/var/lib/ollama";
    uid = 988; # Keep the existing UID
    extraGroups = [ "render" "video" ]; # Add GPU access groups
  };

  users.groups.ollama = {
    gid = 983; # Keep the existing GID
  };

  # Ensure ollama directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0755 ollama ollama -"
    "d /var/lib/ollama/models 0755 ollama ollama -"
  ];

  # Install ROCm packages for AMD GPU acceleration
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-runtime
    rocmPackages.rocm-device-libs
    rocmPackages.rocm-smi
    rocmPackages.hipify
  ];

  # Set up ROCm environment variables and memory optimizations
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1"; # Enable older GPU support if needed
    HSA_OVERRIDE_GFX_VERSION = "11.0.2"; # Override for gfx1036 (Granite Ridge) compatibility

    # Large model memory optimizations
    OLLAMA_HOST = "127.0.0.1:11434";
    OLLAMA_NUM_PARALLEL = "1"; # Limit parallel requests to save memory
    OLLAMA_MAX_LOADED_MODELS = "1"; # Only keep one model in memory
    OLLAMA_FLASH_ATTENTION = "true"; # Use flash attention for memory efficiency
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm; # Use ROCm-enabled ollama package

    user = "ollama";
    group = "ollama";

    home = "/var/lib/ollama";
    models = "/var/lib/ollama/models";

    loadModels = [
      # "llama3.2:3b"        # Temporarily disabled to free space
      # "gpt-oss:20b"      # OpenAI's new open-weight 20B model
      # "gpt-oss:120b"     # OpenAI's new open-weight 120B model
      # "llama3.2-vision"
    ];
    acceleration = "rocm";
  };

  # Override the systemd service to disable DynamicUser
  systemd.services.ollama = {
    serviceConfig = {
      DynamicUser = pkgs.lib.mkForce false;
    };
    environment = {
      HSA_OVERRIDE_GFX_VERSION = "11.0.2"; # Override for AMD Granite Ridge gfx1036
      ROC_ENABLE_PRE_VEGA = "1";
    };
  };

  services.nextjs-ollama-llm-ui.enable = true;

  # Ollama models directory is now persisted via impermanence in persistence.nix
}
