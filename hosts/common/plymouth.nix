{ config, pkgs, lib, ... }:
{
  # Enable Plymouth boot splash
  boot.plymouth = {
    enable = true;
    # Let Stylix handle the theme - it creates a cohesive look
    # with your system's color scheme and styling
    # Stylix will automatically configure the "stylix" Plymouth theme

    # If you want to override Stylix later, you can uncomment:
    # theme = lib.mkForce "nixos-bgrt";  # NixOS logo with spinner
    # theme = lib.mkForce "spinner";     # Simple Windows-like spinner
    # theme = lib.mkForce "bgrt";        # UEFI logo with spinner
  };

  # Enable Plymouth in the initrd (early boot)
  boot.initrd.enable = true;
  boot.kernelParams = [
    # Enable Plymouth early in the boot process
    "splash"
    # Quiet boot - reduces text output during boot
    "quiet"
    # Hide cursor during boot
    "vt.global_cursor_default=0"
    # Reduce log level to minimize text output
    "loglevel=3"
    # Disable systemd status messages during boot
    "rd.systemd.show_status=false"
    # Disable udev logging during boot
    "rd.udev.log_level=3"
    # Hide ACPI messages
    "acpi_osi=Linux"
  ];

  # Ensure Plymouth works with your display setup
  boot.plymouth.extraConfig = ''
    [Daemon]
    # Theme is handled by Stylix automatically
    ShowDelay=0
    DeviceTimeout=8
  '';

  # Add Plymouth theme packages
  environment.systemPackages = with pkgs; [
    plymouth
    # Stylix will automatically provide the necessary theme packages
    # Optional additional themes you can experiment with later:
    # nixos-bgrt-plymouth       # NixOS BGRT theme with spinning NixOS logo
    # adi1090x-plymouth-themes  # Collection of beautiful themes
    # catppuccin-plymouth       # Catppuccin theme
    # plymouth-matrix-theme     # Matrix-style theme
  ];

  # Ensure Plymouth quits gracefully to display manager
  systemd.services.plymouth-quit-wait.enable = lib.mkDefault true;
  systemd.services.plymouth-quit.enable = lib.mkDefault true;
}
