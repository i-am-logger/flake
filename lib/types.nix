{ lib }:

with lib;

{
  # Enhanced types for product specification
  product = {
    # System type
    systemType = types.enum [ "workstation" "server" "laptop" "desktop" ];
    
    # Hardware types
    componentType = types.enum [ "cpu" "gpu" "audio" "bluetooth" "wifi" "ethernet" "storage" "usb" ];
    
    # Capability types
    securityLevel = types.enum [ "none" "low" "medium" "high" "maximum" ];
    desktopType = types.enum [ "minimal" "standard" "full" ];
    developmentType = types.enum [ "basic" "containers" "full" ];
    
    # Hardware vendors
    cpuVendor = types.enum [ "amd" "intel" ];
    gpuVendor = types.enum [ "amd" "nvidia" "intel" ];
    
    # User roles
    userRole = types.enum [ "admin" "developer" "user" ];
    
    # Shell types
    shellType = types.enum [ "bash" "zsh" "fish" "nushell" ];
    
    # Performance profiles
    performanceProfile = types.enum [ "performance" "balanced" "powersave" ];
    
    # Component specification
    component = types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable this component";
        };
      };
    };
  };
}
