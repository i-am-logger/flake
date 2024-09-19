{ pkgs, ... }:

{
  # Laptop can't correctly suspend if wlan is active
  powerManagement = {
    powerDownCommands = ''
      ${pkgs.util-linux}/bin/rfkill block wlan
    '';
    resumeCommands = ''
      ${pkgs.util-linux}/bin/rfkill unblock wlan
    '';
  };
}
