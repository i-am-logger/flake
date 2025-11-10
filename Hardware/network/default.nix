{ config, lib, pkgs, ... }:

{
  options.hardware.network = {
    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable WiFi support";
      };
      
      standard = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "WiFi standard (e.g., 'wifi7', 'wifi6e', 'wifi6')";
      };
    };
    
    ethernet = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Ethernet support";
      };
      
      speed = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Ethernet speed (e.g., '2.5gbe', '10gbe')";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.hardware.network.wifi.enable || config.hardware.network.ethernet.enable) {
      # Generic network configuration
      networking.networkmanager.enable = lib.mkDefault true;
    })
    
    (lib.mkIf (!config.hardware.network.wifi.enable) {
      networking.wireless.enable = lib.mkDefault false;
    })
  ];
}
