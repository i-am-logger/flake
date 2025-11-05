{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./drivers/windows-dual-boot.nix
    ./drivers/uefi-boot.nix  # Keep for kernel config
    
    # Shared hardware modules  
    ../../../cpu/intel
    ../../../gpu/nvidia
    ../../../audio/realtek
    ../../../bluetooth/realtek
    ../../../network
    ../../../boot
  ];

  # Platform architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
