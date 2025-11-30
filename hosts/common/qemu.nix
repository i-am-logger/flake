{ pkgs
, username
, ...
}:
{
  virtualisation.libvirtd = {
    enable = true;
    # swtpm.enable = true;
    # ovmf.enable = true;
    qemu.package = pkgs.qemu_full;
  };

  virtualisation.libvirtd.qemu.verbatimConfig = ''
    virtio_user_rng = "on"
    virtio_user_fs = "on"
    memory_backing_dir = "/dev/shm"
  '';
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
