{pkgs, ...}: {
  services.udev.packages = [pkgs.qhyccd_sdk];
}
