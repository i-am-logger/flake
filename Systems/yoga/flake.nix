{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.disko.url = "github:nix-community/disko/latest";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, disko, nixpkgs }: {
    nixosConfigurations.yoga = nixpkgs.legacyPackages.x86_64-linux.nixos [
      ./configuration.nix
      disko.nixosModules.disko
      {
        disko.devices = import ./disko.nix {
          lib = nixpkgs.lib;
        };
        # disko.devices = {
        #   disk = {
        #     main = {
        #       # When using disko-install, we will overwrite this value from the commandline
        #       device = "/dev/disk/by-id/some-disk-id";
        #       type = "disk";
        #       content = {
        #         type = "gpt";
        #         partitions = {
        #           MBR = {
        #             type = "EF02"; # for grub MBR
        #             size = "1M";
        #             priority = 1; # Needs to be first partition
        #           };
        #           ESP = {
        #             type = "EF00";
        #             size = "500M";
        #             content = {
        #               type = "filesystem";
        #               format = "vfat";
        #               mountpoint = "/boot";
        #               mountOptions = [ "umask=0077" ];
        #             };
        #           };
        #           root = {
        #             size = "100%";
        #             content = {
        #               type = "filesystem";
        #               format = "ext4";
        #               mountpoint = "/";
        #             };
        #           };
        #         };
        #       };
        #     };
        #   };
        # };
      }
    ];
  };
}
