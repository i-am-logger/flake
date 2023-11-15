{ pkgs
, username
, ...
}: {
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  # programs.dconf.enable = true;
  users.users.${username}.extraGroups = [ "libvirtd" ];

  services.qemuGuest.enable = true;
  # services.spice-vdagentd.enable = true;

  # environment.systemPackages = with pkgs; [
  # spice
  # spice
  # win-spice
  # virt-viewer
  # virt-manager
  # ];
  # dconf.settings = {
  #   "org/virt-manager/virt-manager/connections" = {
  #     autoconnect = [ "qemu:///system" ];
  #     uris = [ "qemu:///system" ];
  #   };
  # };
}
