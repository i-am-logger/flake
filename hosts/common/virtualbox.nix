# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs
, config
, username
, ...
}:

{
  environment.systemPackages = with pkgs; [
    # virtualization
    virtualboxWithExtpack # TODO: configuration
  ];
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
    enableHardening = false;
  };
  users.extraGroups.vboxusers.members = [ username ];

  boot.extraModulePackages = [ config.boot.kernelPackages.virtualbox ];
  boot.kernelModules = [
    "vboxdrv"
    "vboxnetflt"
    "vboxnetadp"
  ]; # virtualisation.virtualbox.guest.enable = true;

  boot.blacklistedKernelModules = [
    "kvm"
    "kvm-intel"
  ];
}
