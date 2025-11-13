{ config, lib, pkgs, ... }:

{
  options.hardware.gpu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GPU support";
    };
    
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Specific GPU model (e.g., 'nvidia-rtx4080', 'nvidia-rtx4090')";
    };
  };

  config = lib.mkIf config.hardware.gpu.enable {
    # NVIDIA GPU driver configuration
    
    # Enable NVIDIA drivers
    services.xserver.videoDrivers = [ "nvidia" ];
    
    hardware.nvidia = {
      modesetting.enable = lib.mkDefault true;
      powerManagement.enable = lib.mkDefault true;
      open = lib.mkDefault false;  # Use proprietary driver
      nvidiaSettings = lib.mkDefault true;
    };

    # Enable graphics support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
