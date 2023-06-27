# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, pkgs, inputs, user, ... }:

{
  imports =
    [ 
      # hardware      
      handlink/hardware-configuration.nix
      common/nvidia.nix
      common/bluetooth.nix
      handlink/power_management.nix
      
      # boot
      handlink/boot.nix
      common/console.nix

      # system
      common/system.nix
      common/nix.nix
      handlink/network.nix
      common/sound.nix # TODO: fix & power management

      common/environment.nix
      common/hyprland.nix
      #./x11_plasma.nix
      users/snick.nix
    ];
}