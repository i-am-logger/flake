# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.bash;
  users.users.logger = {
    name = "logger";
    initialPassword = "";
    isNormalUser = true;
    description = "Logger";
    extraGroups = [
      "networkmanager"
      "input"
      "wheel"
      "gpu"
      "video"
      "render"
      "audio"
      "udev"
      "plugdev"
      "usb"
      "disk"
      "dialout"
    ];
    shell = pkgs.bash;
  };
}
