# ads-dev1: one 8 TB NVMe, ONE btrfs pool, two subvolumes.
#
# This is deliberately NOT yoga's layout. yoga splits /nix and /persist into
# separate partitions and pins /nix at 128G -- a number that is a standing
# liability, because a from-source kernel build plus a few uncollected
# generations fills it and borrowing from the 100% /persist partition means
# repartitioning. One pool on 8 TB makes that question disappear, and btrfs
# behaves better with headroom: a 128G filesystem at 90% full is a far worse
# place to be than an 8 T one at 5%.
#
# What one pool gives up is blast-radius isolation. On yoga a runaway build can
# only fill /nix; here it would starve /persist too. Accepted: it is one physical
# disk either way, so a device failure takes both regardless, and the failure
# mode is slow and visible rather than sudden. If hard isolation is ever wanted
# the mechanism is a btrfs qgroup limit on /nix -- a runtime-adjustable ceiling
# rather than a partition -- but qgroups carry per-transaction accounting
# overhead upstream still warns about, so aggressive nix.gc is the better
# defence.
#
# MOUNT OPTION SCOPE MATTERS HERE, and it is narrower than it looks. Nearly
# every btrfs option -- `compress`, `discard`, `space_cache`, `commit` -- is
# FILESYSTEM-wide and first-mount-wins; only the VFS ones such as `noatime`
# are genuinely per-mount. Two subvolumes of ONE filesystem therefore cannot
# disagree about compression, so both mounts below state identical btrfs
# options and the lists read the same on purpose. Measured during this
# machine's install, not assumed: a /persist mount issued with
# compress=zstd:3 came up reporting compress=zstd:1 because /nix mounted
# first, with no error anywhere.
#
# No swap device. A btrfs swapfile needs its own nodatacow subvolume and cannot
# be snapshotted, and with 187 GiB of RAM plus my.performance's zram there is
# nothing to gain outside hibernation.
_:
{
  nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [ "size=32G" "mode=755" "noatime" ];
    };
    "/tmp" = {
      fsType = "tmpfs";
      # Nix builds here, and this box builds with 128 threads. tmpfs is
      # swappable, so an over-large /tmp costs nothing until it is used.
      mountOptions = [ "size=96G" "mode=755" "noatime" ];
    };
  };

  disk = {
    main = {
      type = "disk";
      # by-id rather than /dev/nvme0n1: adding a second NVMe renumbers the kernel
      # name, and this string is what disko-install is pointed at.
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN8100_HS_8000GB_25411S800410";
      content = {
        type = "gpt";
        partitions = {
          boot = { size = "2M"; type = "EF02"; }; # grub MBR stub
          ESP = {
            size = "2G";
            type = "EF00";
            content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
          };
          main = {
            size = "100%";
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
                    # NO autodefrag. It targets small random writes on spinning
                    # rust; on NVMe it is pure write amplification, rewriting
                    # extents that were never slow to read.
                  ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "noatime"
                    # ONE LEVEL FOR THE WHOLE POOL, and not by preference.
                    #
                    # compress= is a FILESYSTEM-wide btrfs option, not a
                    # per-subvolume one: the first mount of the filesystem sets it
                    # and every later subvolume mount inherits it. Verified on this
                    # machine during the install -- disko issued
                    # `mount -o compress=zstd:3 ... subvol=/persist` and the kernel
                    # reported compress=zstd:1, silently, because /nix had mounted
                    # first. No error, just a different filesystem than the one
                    # written down.
                    #
                    # yoga can genuinely run zstd:1 on /nix and zstd:3 on /persist
                    # because there they are two SEPARATE partitions, i.e. two
                    # filesystems. Here they are two subvolumes of one, which is
                    # the trade the single pool makes.
                    #
                    # zstd:1 is the right single answer: /nix dominates write
                    # volume and is highly compressible, while the bulk of
                    # /persist by size is Media/, which zstd skips as
                    # incompressible at any level.
                    "compress=zstd:1"
                    "discard=async"
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
