{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
      vpl-gpu-rt
    ];
  };

  services.xserver.videoDrivers = [
    "intel"
    "nvidia"
  ];

  nixpkgs.config.cudaSupport = true;

  hardware.nvidia.dynamicBoost.enable = false;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
    prime.offload.enable = lib.mkForce false;
    prime.offload.enableOffloadCmd = lib.mkForce false;
    prime.sync.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.systemPackages = with pkgs; [
    cudatoolkit
    nvtopPackages.full
  ];

  boot.kernelModules = [
    "i915"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];
}
