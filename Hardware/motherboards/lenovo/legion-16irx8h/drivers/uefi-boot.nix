{ config, lib, pkgs, ... }:

{
  # UEFI boot configuration for Lenovo Legion Pro 7 16IRX8H

  # Bootloader - disabled for lanzaboote (Secure Boot)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 2; # Fast boot

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hardware detected kernel modules
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  boot.extraModulePackages = [ ];

  # Mask audit-rules service (cosmetic fix for this hardware)
  # Rules are loaded early via kernel cmdline
  systemd.services.audit-rules.enable = false;
}
