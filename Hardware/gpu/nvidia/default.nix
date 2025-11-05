{ config, lib, pkgs, ... }:

{
  # NVIDIA GPU driver configuration
  # TODO: Add NVIDIA-specific configuration when needed
  
  # Enable graphics support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
