{ config, lib, pkgs, ... }:

{
  # Realtek Bluetooth configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
}
