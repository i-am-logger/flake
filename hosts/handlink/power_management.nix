# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  self,
  pkgs,
  inputs,
  user,
  ...
}:
{
  powerManagement = {
    enable = true;
    # powertop.enable = true;
  };
  networking.interfaces.enp118s0.wakeOnLan.enable = false;
  networking.networkmanager.wifi.powersave = true;

  # services.logind.enable = true;
  services.logind.lidSwitchExternalPower = "ignore";

  services.upower = {
    enable = true;
  };

  services.cpupower-gui = {
    enable = true;
  };

  programs.light.enable = true;

  # https://github.com/johnfanv2/LenovoLegionLinux
  environment.systemPackages = with pkgs; [
    powertop
    acpi
    lm_sensors
    # powerprofilesctl
  ];
}
