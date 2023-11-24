# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ username, ... }: {
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
    common/security.nix
    common/nix.nix
    handlink/network.nix
    common/sound.nix # TODO: fix & power management
    common/v4l2loopback.nix

    common/environment.nix
    common/yubikey-gpg.nix
    common/hyprland.nix
    common/1password.nix
    common/qemu.nix
    common/ros2.nix
    common/docker.nix
    #common/virtualbox.nix

    users/${username}.nix

    # Sky360
    common/github-runner.nix
    # (
    #   ../Systems/sky360
    # )
  ];
}
