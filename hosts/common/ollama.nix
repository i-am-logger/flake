{
  pkgs,
  ...
}:

{
  # Define ollama user and group explicitly
  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    home = "/var/lib/ollama";
    uid = 988;  # Keep the existing UID
  };
  
  users.groups.ollama = {
    gid = 983;  # Keep the existing GID
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama;

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
  };

  services.nextjs-ollama-llm-ui.enable = true;

  # Ollama models directory is now persisted via impermanence in persistence.nix
}
