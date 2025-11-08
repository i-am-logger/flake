{ config, lib, pkgs, ... }:

{
  # Bluetooth hardware support - disabled by default for security/battery
  # Enable when needed: systemctl start bluetooth.service
  # Bluetooth configuration (Legion-specific optimizations moved to nixos-hardware)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Don't power on at boot for battery saving
    settings = {
      General = {
        # Basic compatibility fixes
        ControllerMode = "dual";
        FastConnectable = "true";
      };
    };
  };

  services.blueman.enable = true;
  services.dbus.packages = [ pkgs.blueman ];

  # Ensure bluetooth service doesn't fail on mode setting
  systemd.services.bluetooth = {
    serviceConfig = {
      # Add restart on failure
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
