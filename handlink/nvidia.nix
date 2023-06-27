
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  hardware.opengl = {
    enable = true;

    # Vulkan
    #driSupport = true;


    #driSupport = true;

    # VA-API
    #extraPackages = with pkgs; [
    #  vaapiVdpau
    #  libvdpau-va-gl
    #];
  };

  # Nvidia Drivers
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    
    # Open drivers (NVreg_OpenRmEnableUnsupportedGpus=1)
    open = false;

    # nvidia-drm.modeset=1
    modesetting.enable = true;

    # Allow headless mode
    #nvidiaPersistenced = true;

    # NVreg_PreserveVideoMemoryAllocations=1
    powerManagement.enable = true;

    # fixed screen tearing
    #forceFullCompositionPipeline = true;

  };
}
