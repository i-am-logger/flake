{ ... }:
{
  nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=16G" # Reduced from 32G to free more RAM for GPU
        "mode=755"
        "noatime" # Reduce disk I/O overhead
      ];
    };
    "/tmp" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=8G" # Moderate size for temporary files
        "mode=755"
        "noatime"
      ];
    };
    # Dedicated tmpfs for GPU compute workloads
    "/tmp/gpu-workdir" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=16G" # Fast storage for GPU temp files
        "mode=755"
        "noatime"
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
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          nix = {
            size = "128G"; # Reduced to 128GB, still plenty for nix store
            content = {
              type = "btrfs";
              subvolumes = {
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "noatime"
                    "compress=zstd"
                    "autodefrag"
                    "space_cache=v2"
                  ];
                };
              };
            };
          };
          persist = {
            size = "100%"; # Remaining space for /persist
            content = {
              type = "btrfs";
              subvolumes = {
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "noatime"
                    "autodefrag"
                    "space_cache=v2"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
