{ ... }: {
  services = {
    # USB Automounting
    gvfs.enable = true;
    devmon.enable = true;
  };

  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
  };
}
