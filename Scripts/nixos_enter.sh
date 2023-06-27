mount /dev/nvme0n1p2 -o subvol=root /mnt/
mount /dev/nvme0n1p2 -o subvol=home /mnt/home
mount /dev/nvme0n1p2 -o subvol=nix /mnt/nix
mount /dev/nvme0n1p2 -o subvol=swap /mnt/swap
mount /dev/nvme0n1p1 /mnt/boot
