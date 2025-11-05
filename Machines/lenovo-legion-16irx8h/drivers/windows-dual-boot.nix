{ config, lib, pkgs, ... }:

{
  # Windows dual-boot hardware configuration
  # Hardware-level settings needed for dual-boot with Windows
  
  # Keep hardware clock in local time (Windows expects this)
  time.hardwareClockInLocalTime = true;
  
  # Support NTFS filesystem (for Windows partition)
  boot.supportedFilesystems = [ "ntfs" ];
  
  # Mount Windows partition (read-only for safety)
  fileSystems."/home/logger/mnt/windows" = {
    device = "/dev/disk/by-uuid/A03C41603C413318";
    fsType = "ntfs";
    options = [ "ro" "uid=1000" "gid=100" "dmask=022" "fmask=133" ];
    noCheck = true;
  };
}
