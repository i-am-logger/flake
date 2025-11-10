{ config, lib, pkgs, modulesPath, ... }:

{
  options.hardware.motherboard.gigabyte-x870e = {
    enable = lib.mkEnableOption "Gigabyte X870E AORUS ELITE WIFI7 motherboard";
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

    # Platform architecture
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    
    # Motherboard has these components available
    # They can be individually enabled/disabled via hardware.cpu.enable, hardware.gpu.enable, etc.
  };
}
