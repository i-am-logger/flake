{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      # vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      vpl-gpu-rt
    ];
  };

  services.xserver.videoDrivers = [
    "intel"
    "nvidia"
  ];

  # services.udev.extraRules = ''
  #   KERNEL=="card[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0666"
  # '';

  nixpkgs.config.cudaSupport = true;

  hardware.nvidia.dynamicBoost.enable = true;
  hardware.nvidia = {
    open = false; # true;
    modesetting.enable = true;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
    prime.offload.enable = lib.mkForce false;
    prime.offload.enableOffloadCmd = lib.mkForce false;
    prime.sync.enable = true;
    # nvidia-persistenced

    # persistenced
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
  # services.udev.extraRules = ''
  #   KERNEL=="nvidia*", RUN+="/run/current-system/sw/bin/chmod 0666 %E{DEVNAME}"
  # '';

  environment.systemPackages = with pkgs; [
    cudatoolkit
    linuxPackages.nvidia_x11
    nvidia-docker
  ];

  boot.kernelModules = [
    "i915"
    "intel"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ]; # ""

  # systemd.services.nvidia-control-devices = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.ExecStart = "${pkgs.bash}/bin/bash -c 'chmod 666 /dev/nvidia* /dev/nvidiactl'";
  # };
  # systemd.services.nvidia-control-devices = {
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
  # };

  # specialisation = {
  #   on-the-go.configuration = {
  #     system.nixos.tags = [ "on-the-go" ];
  #     hardware.nvidia = {
  #       # prime.offload.enableOffloadCmd = lib.mkForce true;
  #       # prime.sync.enable = lib.mkForce false;
  #     };
  #   };
  # };
}
