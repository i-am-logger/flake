# Example product specifications demonstrating different complexity levels
# Choose the level that matches your needs

{ myLib }:

let
  dsl = myLib.dsl;
in

{
  # LEVEL 1: Ultra-Simple (Beginner)
  # Just 3 parameters - works out of the box
  
  simple = dsl.quickSystem 
    "example-workstation"                    # Name
    "gigabyte-x870e-aorus-elite-wifi7"       # Hardware
    "logger";                                # User
  
  # That's it! You get:
  # - Developer workstation (security: high, desktop: full, dev: containers)
  # - Performance-optimized settings
  # - All hardware components enabled
  
  
  # LEVEL 2: Preset-based (Intermediate)
  # Choose a preset, customize specific things
  
  preset-based = dsl.simpleSystem {
    name = "example-workstation";
    hardware = "gigabyte-x870e-aorus-elite-wifi7";
    preset = "workstation.poweruser";
    
    overrides = {
      users = [ "logger" ];
      system.timezone = "America/Denver";
      capabilities.security.features.yubikey = true;
    };
  };
  
  
  # LEVEL 3: Full Control (Advanced)
  # Complete declarative specification
  
  full-control = with dsl; system "example-workstation" {
    type = workstation;
    purpose = "Example demonstrating full product-driven syntax";
    
    hardware = {
      platform = "gigabyte-x870e-aorus-elite-wifi7";
      
      # Component overrides (optional)
      components = {
        # All components enabled by default
        # Can disable specific ones:
        # bluetooth.enable = false;
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

