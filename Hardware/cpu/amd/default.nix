{ config, lib, pkgs, ... }:

{
  # AMD CPU configuration
  boot.kernelModules = [ "kvm-amd" ];
  
  # CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
