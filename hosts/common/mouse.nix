{
  pkgs,
  ...
}:

{
  # Enable ratbagd service for configuring the mouse
  services.ratbagd.enable = true;

  # Install Piper (GUI for configuring the mouse)
  environment.systemPackages = with pkgs; [
    piper
    usbutils # For lsusb and other USB utilities
  ];

  # For better gaming experience, consider disabling mouse acceleration
  services.xserver.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat"; # Disable mouse acceleration
      accelSpeed = "0"; # Neutral acceleration speed
    };
  };
}
