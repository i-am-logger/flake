{
  config,
  pkgs,
  username,
  secrets,
  sops,
  ...
}: {
  sops.age.keyFile = "/home/snick/.config/sops/age/keys.txt";
  sops.secrets."github/snick/runner_token" = {
    format = "yaml";
    sopsFile = "${secrets}/github/snick/runner_token.yaml";
  };

  # services.github-runner = {
  # enable = true;
  # url = "https://github.com/realsnick/sky360";
  # tokenFile = config.sops.secrets."github/snick/runner_token".path;
  # extraPackages = [config.virtualisation.docker.package];
  # nodeRuntimes = ["node16"]; mark insecure
  # };

  virtualisation.docker.enable = true;

  systemd.services.github-runner.serviceConfig.SupplementaryGroups = ["docker"];
}
