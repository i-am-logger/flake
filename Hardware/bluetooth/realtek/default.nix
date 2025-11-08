{ config, lib, pkgs, ... }:

{
  # Realtek Bluetooth configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = lib.mkDefault true;
  };
  services.blueman.enable = true;
}
