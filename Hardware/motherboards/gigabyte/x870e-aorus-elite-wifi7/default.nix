{ config, lib, pkgs, modulesPath, ... }:

{
  options.hardware.motherboard.gigabyte-x870e = {
    enable = lib.mkEnableOption "Gigabyte X870E AORUS ELITE WIFI7 motherboard";
    
    # CPU compatibility list
    compatibleCpus = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "amd-ryzen9-7950x3d"
        "amd-ryzen9-7950x"
        "amd-ryzen9-7900x"
        "amd-ryzen9-7900"
        "amd-ryzen7-7800x3d"
        "amd-ryzen7-7700x"
        "amd-ryzen5-7600x"
        "amd-ryzen5-7600"
      ];
      description = "List of compatible CPU models for this motherboard";
      readOnly = true;
    };
    
    # GPU compatibility
    compatibleGpus = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "amd-radeon-780m"      # Integrated
        "amd-radeon-7900xtx"
        "amd-radeon-7900xt"
        "amd-radeon-7800xt"
        "nvidia-rtx4090"
        "nvidia-rtx4080"
        "nvidia-rtx4070ti"
        "nvidia-rtx4060ti"
      ];
      description = "List of compatible GPU models for this motherboard";
      readOnly = true;
    };
    
    # WiFi standards supported
    supportedWifi = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wifi4" "wifi5" "wifi6" "wifi6e" "wifi7" ];
      description = "WiFi standards supported by this motherboard";
      readOnly = true;
    };
    
    # Ethernet speeds supported
    supportedEthernet = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1gbe" "2.5gbe" ];
      description = "Ethernet speeds supported by this motherboard";
      readOnly = true;
    };
  };

  config = lib.mkIf config.hardware.motherboard.gigabyte-x870e.enable {
    # Always import hardware configuration and boot config
    imports = [
      ./hardware-configuration.nix
      ./drivers/uefi-boot.nix
      ../../../boot
    ];

    # Enable secure boot by default
    hardware.boot.secure = lib.mkDefault true;

    # Platform architecture - force to prevent accidental override
    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    
    # Motherboard chipset: AMD X870E
    # Socket: AM5
    # Components can be individually enabled/disabled via hardware.cpu.enable, hardware.gpu.enable, etc.
  };
}
