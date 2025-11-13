{ config, lib, pkgs, ... }:

{
  options.hardware.bluetooth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Bluetooth support";
    };
  };

  config = lib.mkIf config.hardware.bluetooth.enable {
    # Realtek Bluetooth configuration
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = lib.mkDefault true;
    };
    services.blueman.enable = true;
  };
}
