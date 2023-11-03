{ pkgs, ... }: {
  # services.udev.packages = [pkgs.qhyccd_sdk];
  services.udev.packages = [ pkgs.indi-full ];
}
