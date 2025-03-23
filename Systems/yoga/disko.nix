{ ... }: {
  nodev = {
    "/tmp" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=28G"
        "mode=755"
      ];
    };
  };

  disk = {
    main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "2M";
            type = "EF02"; # for grub MBR
          };
          ESP = {
            size = "2G";
            # priority = 1;
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";

              subvolumes = {
                "SYSTEM" = { };
                "SYSTEM/rootfs" = {
                  mountpoint = "/";
                  mountOptions = [ "noatime" ];
                };
                "SYSTEM/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "noatime" "compress=zstd" ];
                };

                "DATA" = { };
                "DATA/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
