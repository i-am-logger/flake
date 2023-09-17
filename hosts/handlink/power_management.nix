# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  self,
  pkgs,
  inputs,
  user,
  ...
}: {
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  networking.interfaces.enp118s0.wakeOnLan.enable = false;
  networking.networkmanager.wifi.powersave = true;

  # hardware.nvidia.powerManagement.enable = true;

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    powertop
    acpi
  ];
}
