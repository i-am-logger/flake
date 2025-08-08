{ pkgs, ... }:

{
  # Add Stream Deck udev rules for hardware access
  services.udev.packages = [
    pkgs.streamdeck-ui
  ];

  # Enable udev rules for Stream Deck devices
  services.udev.extraRules = ''
    # Stream Deck Original
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE="0664", GROUP="users"
    # Stream Deck Mini  
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE="0664", GROUP="users"
    # Stream Deck XL
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE="0664", GROUP="users"
    # Stream Deck V2
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE="0664", GROUP="users"
    # Stream Deck MK.2
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE="0664", GROUP="users"
    # Stream Deck Plus
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", MODE="0664", GROUP="users"
  '';

  # Ensure the user is in the required groups
  users.groups.streamdeck = {};
  
  # Add necessary system packages
  environment.systemPackages = with pkgs; [
    streamdeck-ui
  ];
}
