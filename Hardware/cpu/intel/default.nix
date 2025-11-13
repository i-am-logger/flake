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
      description = "Specific CPU model (e.g., 'intel-i9-13900hx', 'intel-xeon')";
    };
  };

  config = lib.mkIf config.hardware.cpu.enable {
    # Intel CPU configuration
    boot.kernelModules = [ "kvm-intel" ];

    # CPU microcode updates
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    
    # Model-specific optimizations can be added here
  };
}
