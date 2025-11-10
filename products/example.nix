# Example product specifications demonstrating the unified system approach
# All complexity levels use the same 'system' function

{ myLib }:

let
  dsl = myLib.dsl;
in

{
  # SIMPLE: Using a preset with minimal configuration
  # Preset provides opinionated defaults, you just override what you need
  
  simple-preset = with dsl; system "simple-workstation" {
    preset = "workstation.developer";  # Opinionated preset
    
    # Just specify the essentials
    hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
    users = [ "logger" ];
    system.timezone = "America/Denver";
  };
  
  # The preset provides:
  # - type = workstation
  # - capabilities.security.level = high
  # - capabilities.desktop.type = full
  # - capabilities.development.type = containers
  # - system.performance.profile = performance
  
  
  # INTERMEDIATE: Preset with custom overrides
  
  custom-preset = with dsl; system "custom-workstation" {
    preset = "laptop.travel";  # Start with travel preset
    
    # Override specific parts
    hardware.platform = "lenovo-legion-16irx8h";
    users = [ "alice" ];
    
    # Override preset defaults
    capabilities = {
      desktop = {
        type = standard;  # Override from minimal
        terminal = alacritty;
      };
    };
    
    system.timezone = "Europe/London";
  };
  
  
  # ADVANCED: Full specification without preset
  
  full-control = with dsl; system "full-workstation" {
    type = workstation;
    purpose = "High-performance development workstation";
    
    hardware = {
      platform = "gigabyte-x870e-aorus-elite-wifi7";
      
      # Component control
      components = {
        bluetooth.enable = false;  # Disable if not needed
      };
    };
    
    capabilities = {
      security = {
        level = high;
        features.yubikey = true;
      };
      
      desktop = {
        type = full;
        terminal = warp;
        editor = vscode;
      };
      
      development = {
        type = containers;
      };
    };
    
    users = [ "logger" ];
    
    system = {
      timezone = "America/Denver";
      locale = "en_US.UTF-8";
      
      network = {
        manager = "networkmanager";
        wireless = false;
      };
      
      performance = {
        tcp-congestion-control = "bbr";
        vm-swappiness = 1;
      };
    };
  };
}

