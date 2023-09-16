# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{username, ...}: {
  imports = [
    # hardware
    handlink/hardware-configuration.nix
    #common/nvidia.nix
    common/bluetooth.nix
    handlink/power_management.nix
    handlink/power_management2.nix
    handlink/udev.nix

    # boot
    handlink/boot.nix
    common/console.nix

    # system
    common/system.nix
    common/security.nix
    common/nix.nix
    handlink/network.nix
    common/sound.nix # TODO: fix & power management

    common/environment.nix
    common/yubikey-gpg.nix
    common/1password.nix
    common/qemu.nix
    common/docker.nix
    #common/virtualbox.nix

    common/github-runner.nix
    #common/hyprland.nix
    #common/x11_plasma.nix
    users/${username}.nix
  ];
}
