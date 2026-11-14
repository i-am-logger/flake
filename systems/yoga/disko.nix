_:
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
        "size=28G" # Restored to original size for temporary files
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
                    # The store is very compressible; level 1 keeps most of the
                    # ratio for a fraction of the CPU, and this is paid on every
                    # build write.
                    "compress=zstd:1"
                    # Queued, rate-limited TRIM -- the modern replacement for
                    # periodic fstrim. my.hardware.storage.ssd still schedules
                    # weekly fstrim, which becomes a cheap no-op.
                    "discard=async"
                    "space_cache=v2"
                    # autodefrag REMOVED. It targets small random writes on
                    # spinning rust; on NVMe it is pure write amplification,
                    # rewriting extents that were never slow to read.
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
                    # THIS LEVEL ACTUALLY APPLIES, unlike the same line would on
                    # ads-dev1. compress= is a FILESYSTEM-wide btrfs option with
                    # first-mount-wins semantics, so two subvolumes of one pool
                    # cannot differ -- but here /nix and /persist are separate
                    # PARTITIONS, hence separate filesystems, each with its own
                    # first mount. See systems/ads-dev1/disko.nix, where the
                    # single-pool layout was measured silently collapsing zstd:3
                    # into zstd:1.
                    #
                    # zstd skips incompressible extents, so Media/
                    # costs nothing while text, configs and repos win. Applies
                    # to data written from here on; existing extents are left
                    # as they are (a rewrite would need btrfs fi defrag -czstd).
                    "compress=zstd:3"
                    "discard=async"
                    "space_cache=v2"
                    # autodefrag REMOVED -- see /nix above.
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
