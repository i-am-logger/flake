mount /dev/nvme0n1p4 -o subvol=SYSTEM/rootfs /mnt/
mount /dev/nvme0n1p4 -o subvol=DATA/home /mnt/home
mount /dev/nvme0n1p4 -o subvol=SYSTEM/nix /mnt/nix
#vmount /dev/nvme0n1p2 -o subvol=swap /mnt/swap
mount /dev/nvme0n1p1 /mnt/boot
