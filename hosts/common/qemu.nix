{
  pkgs,
  username,
  ...
}:
{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.${username}.extraGroups = [ "libvirtd" ];

  services.qemuGuest.enable = true;

  environment.systemPackages = with pkgs; [
    virt-top
    iotop
  ];
  nixpkgs.config.qemu-user = {
    qemuFlags = [
      "-cpu"
      "max"
      "-n"
      "0" # Auto-detect CPU cores
      "-U" # Disable user-mode cpu protection
    ];
  };
}
