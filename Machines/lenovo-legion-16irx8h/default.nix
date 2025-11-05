{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./drivers/intel-13900hx-cpu.nix
    ./drivers/nvidia-rtx4080.nix
    ./drivers/realtek-audio.nix
    ./drivers/network.nix
    ./drivers/realtek-bluetooth.nix
    ./drivers/uefi-boot.nix
    ./drivers/windows-dual-boot.nix
  ];

  # Platform architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
