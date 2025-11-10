{ config, lib, pkgs, modulesPath, ... }:

{
  options.hardware.motherboard.lenovo-legion-16irx8h = {
    enable = lib.mkEnableOption "Lenovo Legion 16IRX8H laptop";
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

    # Platform architecture
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    # Motherboard has these components available
    # They can be individually enabled/disabled via hardware.cpu.enable, hardware.gpu.enable, etc.
  };
}
