# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ self
, pkgs
, inputs
, config
, user
, ...
}: {
  #boot.consoleLogLevel = 0;
  #boot.initrd.verbose = false;
  #boot.extraModprobeConfig = ''
  #  options snd-intel-dspcfg dsp_driver=3
  #  options snd_sof sof_debug=128
  #  options snd_usb_audio quirk_alias=19f7000a:05a71020
  #  options thinkpad_acpi fan_control=1
  #'';
  #systemd.services.NetworkManager-wait-online.enable = false;

  # Boot loader - EFI
  boot.loader = {
    timeout = 2;

    # systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      efiSupport = true;
      # efiInstallAsRemovable = true;
      #useOSProber = true;
      device = "nodev";

      # TODO: move to where disk cryptography is done
      enableCryptodisk = true;

      #font = "${pkgs.powerline-fonts}/share/fonts/truetype/Hack-Regular.ttf";
      #fontSize = 32; #only for ttf or otf fonts
      #gfxmodeEfi = "2880x1600";
      #gfxpayloadEfi = "3840x1080";
      #gfxmodeEfi = "3840x1080";
      #    extraConfig = ''
      #      terminal_input console
      #      terminal_output console
      #    '';

      extraEntries = ''
        menuentry "Reboot" {
          reboot
        }
        menuentry "Poweroff" {
          halt
        }
      '';
    };
  };

  boot.plymouth.enable = true;

  boot.kernelParams = [
    #"quiet"
    #"splash"
    "nvidia-drm.modeset=1"
    # For Power consumption in case of NVME SSD
    # was installed.
    "nvme.noacpi=1"
    # For fixing interferences with Fn- action keys
    "video.report_key_events=0"
    "acpi_call"
  ];
  #  boot.supportedFilesystems = [ "btrfs" "ext2" "ext3" "ext4" "exfat" "f2fs" "fat8" "fat16" "fat32" "ntfs" "xfs" "zfs" ];
  boot.supportedFilesystems = [ "btrfs" "ext2" "ext3" "ext4" "exfat" "f2fs" "fat8" "fat16" "fat32" "ntfs" "xfs" ];
  #  boot.supportedFilesystems = [ "ntfs" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
}
