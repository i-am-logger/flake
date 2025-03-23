# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko.nix

# new
#
sudo nix run --extra-experimental-features "nix-command flakes" 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake .#yoga --disk main /dev/nvme0n1
