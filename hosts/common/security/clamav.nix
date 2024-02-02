# https://search.nixos.org/options?channel=23.05&from=0&size=50&sort=relevance&type=packages&query=clamav
{ ... }: {
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
}
