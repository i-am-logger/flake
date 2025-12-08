{ config, lib, pkgs, ... }:

{
  # Filesystem configuration for skyspy-dev
  # Root filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a1633b72-8485-47dc-a52b-ecd35f2e6d03";
    fsType = "ext4";
  };

  # Boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D797-9E9E";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # No swap devices
  swapDevices = [ ];
}
