{ ... }: {
  nodev = {
    "/tmp" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=32G"
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
          swap = {
            size = "100G";
            content = {
              type = "swap";
              randomEncryption = true;
              resumeDevice = true; # resume from hiberation from this device
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              # extraArgs = [ "-f" ]; # override existing partition

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
                # "DATA/home/snick" =      { mountpoint = "/home/snick";      mountOptions = [ "noatime" ]; };
                # "DATa/home/snick/Code" = { mountpoint = "/home/snick/Code"; mountOptions = [ "noatime" "compress=zstd" ]; };
              };
            };
          };
        };
      };
    };
  };
}
