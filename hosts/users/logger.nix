# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.bash;
  users.users.logger = {
    name = "logger";
    hashedPassword = "$6$xSY41iEBAU2B0KdA$Qk/yL0097FNXr2xEKVrjk1M6BUbQNgXYibBqlWwvhcV4h1JDE3bBmz61hynlu4w83ypyxgh66qowBjIkamsDC1";
    isNormalUser = true;
    description = "Ido Samuelson";
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
    packages = with pkgs; [
      sbctl # for secure-boot
    ];
  };

  # Ensure user avatar is accessible to display manager
  system.activationScripts.userAvatar = {
    text = ''
      # Create directory for user icons if it doesn't exist
      mkdir -p /var/lib/AccountsService/icons
      mkdir -p /var/lib/AccountsService/users
      
      # Copy the user avatar to the standard location
      cp /etc/nixos/home/logger/logger.png /var/lib/AccountsService/icons/logger
      chmod 644 /var/lib/AccountsService/icons/logger
      
      # Create AccountsService user configuration
      cat > /var/lib/AccountsService/users/logger << EOF
[User]
Icon=/var/lib/AccountsService/icons/logger
EOF
      chmod 644 /var/lib/AccountsService/users/logger
    '';
    deps = [ "users" ];
  };
}
