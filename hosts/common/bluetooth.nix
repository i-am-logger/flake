{ config, lib, pkgs, ... }:

{
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.dbus.packages = [ pkgs.blueman ];
}
