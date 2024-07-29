# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs, username, ... }: {
  imports = [
    # hardware
    handlink/hardware-configuration.nix
    common/nvidia.nix
    common/bluetooth.nix
    handlink/power_management.nix
    handlink/power_management2.nix
    handlink/udev.nix

    # boot
    handlink/boot.nix
    common/console.nix

    # system
    common/system.nix
    common/security/security.nix
    common/security/yubikey-gpg.nix
    common/security/1password.nix
    common/nix.nix
    handlink/network.nix
    common/sound.nix # TODO: fix & power management
    # common/v4l2loopback.nix

    common/environment.nix
    common/hyprland.nix
    common/qemu.nix

    # common/nextcloud.nix
    # common/sddm.nix
    # common/ros2.nix
    # common/docker.nix
    #common/virtualbox.nix

    users/${username}.nix

    # Sky360
    # common/pure-ftpd/default.nix
    # common/github-runner.nix
    # (
    #   ../Systems/sky360
    # )
  ];

  # support udev rules for zsa voyager's keyboard
  hardware.keyboard.zsa.enable = true;
  # to access ios devices
  services.usbmuxd.enable = true;

  services.trezord.enable = true;
  security.pam.services.swaylock = { };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

}
