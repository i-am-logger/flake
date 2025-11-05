{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./drivers/uefi-boot.nix  # Keep for kernel config
    
    # Shared hardware modules
    ../../../cpu/amd
    ../../../gpu/amd
    ../../../audio/realtek
    ../../../bluetooth/realtek
    ../../../network
    ../../../boot
  ];
  
  # Enable secure boot
  hardware.boot.secure = true;

  # Platform architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
