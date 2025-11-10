{ config, lib, pkgs, modulesPath, ... }:

{
  options.hardware.motherboard.lenovo-legion-16irx8h = {
    enable = lib.mkEnableOption "Lenovo Legion 16IRX8H laptop";
    
    # CPU compatibility list
    compatibleCpus = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "intel-i9-13900hx"
        "intel-i9-13980hx"
        "intel-i7-13700hx"
        "intel-i5-13500hx"
      ];
      description = "List of compatible CPU models for this motherboard";
      readOnly = true;
    };
    
    # GPU compatibility (laptop has specific GPU options)
    compatibleGpus = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "intel-iris-xe"       # Integrated
        "nvidia-rtx4090-mobile"
        "nvidia-rtx4080-mobile"
        "nvidia-rtx4070-mobile"
        "nvidia-rtx4060-mobile"
      ];
      description = "List of compatible GPU models for this laptop";
      readOnly = true;
    };
    
    # WiFi standards supported
    supportedWifi = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wifi6" "wifi6e" ];
      description = "WiFi standards supported by this laptop";
      readOnly = true;
    };
  };

  config = lib.mkIf config.hardware.motherboard.lenovo-legion-16irx8h.enable {
    # Always import hardware configuration and boot config
    imports = [
      ./hardware-configuration.nix
      ./drivers/windows-dual-boot.nix
      ./drivers/uefi-boot.nix
      ../../../boot
    ];

    # NVIDIA PRIME configuration for hybrid graphics
    hardware.nvidia.prime = lib.mkDefault {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Platform architecture - force to prevent accidental override
    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    
    # Laptop: Lenovo Legion 16IRX8H
    # Socket: BGA (soldered)
    # Components can be individually enabled/disabled via hardware.cpu.enable, hardware.gpu.enable, etc.
  };
}
