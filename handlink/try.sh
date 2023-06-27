for i in dev proc sys; do mount --rbind /$i /mnt/$i; done
NIXOS_INSTALL_BOOTLOADER=1 chroot /mnt \
  /nix/var/nix/profiles/system/bin/switch-to-configuration boot