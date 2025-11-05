{ config, lib, pkgs, ... }:

{
  # Intel CPU configuration
  boot.kernelModules = [ "kvm-intel" ];
  
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
