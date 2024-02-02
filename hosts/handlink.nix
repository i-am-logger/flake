# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ pkgs, username, ... }: {
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
    common/security/security.nix
    common/security/yubikey-gpg.nix
    common/security/1password.nix
    common/nix.nix
    handlink/network.nix
    common/sound.nix # TODO: fix & power management
    common/v4l2loopback.nix

    common/environment.nix
    common/hyprland.nix
    common/qemu.nix
    # common/sddm.nix
    # common/ros2.nix
    # common/docker.nix
    #common/virtualbox.nix

    users/${username}.nix

    # Sky360
    # common/pure-ftpd/default.nix
    # common/github-runner.nix
    # (
    #   ../Systems/sky360
    # )
  ];

  # support udev rules for zsa voyager's keyboard
  hardware.keyboard.zsa.enable = true;

  # systemd.user.services.swww = {
  #   description = "Efficient animated wallpaper daemon for wayland";
  #   wantedBy = [ "graphical-session.target" ];
  #   partOf = [ "graphical-session.target" ];
  #   before = [ "default_wall.service" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = ''
  #       ${pkgs.swww}/bin/swww-daemon
  #     '';
  #     ExecStop = "${pkgs.swww}/bin/swww kill";
  #     Restart = "on-failure";
  #   };
  # };
  # systemd.user.services.default_wall = {
  #   description = "default wallpaper";
  #   requires = [ "swww.service" ];
  #   after = [ "swww.service" "graphical-session.target" ];
  #   wantedBy = [ "graphical-session.target" ];
  #   partOf = [ "graphical-session.target" ];
  #   script = ''${default_wall}'';
  #   serviceConfig = {
  #     Type = "oneshot";
  #     Restart = "on-failure";
  #   };
  # };

  security.pam.services.swaylock = { };
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  # };

}
