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
      description = "Specific GPU model (e.g., 'amd-radeon780m', 'amd-radeon')";
    };
  };

  config = lib.mkIf config.hardware.gpu.enable {
    # AMD Radeon GPU driver configuration

    # Load AMD GPU kernel modules
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.kernelModules = [ "amdgpu" ];

    # AMD GPU kernel parameters for optimal performance
    boot.kernelParams = [
      "amdgpu.dc_feature_mask=0xffffffff" # Enable all DC features including DSC
      "amdgpu.deep_color=1" # HDR support
      "amdgpu.dc=1" # Display Core
      "amdgpu.dpm=1" # Dynamic Power Management
      "amdgpu.dp_mst=1" # DisplayPort Multi-Stream Transport
    ];

    # Graphics hardware configuration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl
        libva-utils
      ];
    };
  };
}
