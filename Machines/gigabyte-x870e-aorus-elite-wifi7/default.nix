{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./drivers/amd-integrated-gpu.nix
    ./drivers/realtek-audio.nix
    ./drivers/network.nix
    ./drivers/bluetooth.nix
    ./drivers/uefi-boot.nix
  ];

  # Platform architecture
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
