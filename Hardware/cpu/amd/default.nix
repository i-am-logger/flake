{ config, lib, pkgs, ... }:

{
  options.hardware.cpu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CPU support";
    };
    
    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Specific CPU model (e.g., 'amd-ryzen9-7950x3d', 'amd-ryzen9-7950x')";
    };
  };

  config = lib.mkIf config.hardware.cpu.enable {
    # AMD CPU configuration
    boot.kernelModules = [ "kvm-amd" ];

    # CPU microcode updates
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # Model-specific optimizations
    boot.kernelParams = lib.mkIf (config.hardware.cpu.model == "amd-ryzen9-7950x3d") [
      # 3D V-Cache optimizations
      "amd_pstate=active"
    ];
  };
}
