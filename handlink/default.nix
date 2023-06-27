# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, pkgs, inputs, user, ... }:

{
  imports =
    [ 
      # hardware      
      ./hardware-configuration.nix
      ./nvidia.nix
      ./bluetooth.nix
      ./power_management.nix
      
      # boot
      ./boot.nix
      ./console.nix

      # system
      ./system.nix
      ./nix.nix
      ./network.nix
      #./sound.nix # TODO: fix & power management

      ./hyprland.nix
      #./x11_plasma.nix
      ./users.nix
      ./environment.nix
    ];
}