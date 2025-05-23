{
  pkgs,
  ...
}:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama;

    user = "ollama";
    group = "ollama";

    home = "/var/lib/ollama";
    models = "/var/lib/ollama/models";

    loadModels = [
      # "llama3.2:3b"
      # "llama3.2-vision"
    ];
    acceleration = "cuda";
  };

  services.nextjs-ollama-llm-ui.enable = true;

  # fileSystems."/var/lib/ollama/models" = {
  #   device = "/var/lib/ollama/models";
  #   options = [
  #     "bind"
  #     "persist"
  #   ];
  # };
}
