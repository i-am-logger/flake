{ config, pkgs, lib, ... }:
{
  # Essential systemd-boot configuration for better boot experience
  # Note: Using Lanzaboote for secure boot, so systemd-boot is managed by it
  boot.loader = {
    # Fast boot timeout - 2 seconds
    timeout = lib.mkDefault 2;

    # EFI configuration
    efi = {
      canTouchEfiVariables = lib.mkDefault true;
      efiSysMountPoint = lib.mkDefault "/boot";
    };
  };

  # Keep it simple - just ensure proper console mode for boot menu visibility
  boot.loader.systemd-boot.consoleMode = lib.mkDefault "max";
}
