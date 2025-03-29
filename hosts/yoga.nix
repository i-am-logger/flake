# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs, ... }:
{
  imports = [
    # hardware
    # common/bluetooth.nix
    # common/auto-cpufreq.nix

    # boot
    # handlink/boot.nix
    common/console.nix

    # system
    # common/system.nix
    # common/security/security.nix
    # common/security/yubikey-gpg.nix
    common/security/1password.nix
    common/nix.nix
    # handlink/network.nix
    # common/sound.nix
    # common/v4l2loopback.nix
    common/mouse.nix

    common/environment.nix
    common/hyprland.nix
    # common/notion.nix
    common/binfmt.nix
    # common/qemu.nix
    common/appimage.nix
    common/direnv.nix
    common/xdg.nix
    # common/wlsunset.nix
    # common/docker.nix
    # common/ollama.nix
    # common/n8n.nix
    # common/nextcloud.nix
    # common/sddm.nix
    # common/ros2.nix
    # common/virtualbox.nix

    users/logger.nix
  ];

  services.usbmuxd.enable = true;

  services.fwupd.enable = true; # firmware update
  services.trezord.enable = true;
  # security.pam.services.swaylock = { };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
}
