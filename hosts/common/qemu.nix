{
  pkgs,
  username,
  ...
}: {
  environment.systemPackages = with pkgs; [virt-manager];
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  users.users.${username}.extraGroups = ["libvirtd"];

  services.qemuGuest.enable = true;
}
