# Windows-like Simplicity Examples
# Demonstrating the philosophy: Simple by default, powerful when needed

{ myLib }:

let
  dsl = myLib.dsl;
in

{
  # LEVEL 1: Ultra-Simple (3 parameters - Windows installer level)
  # Just specify: name, hardware, and user
  # Everything else uses smart defaults
  
  minimal-example = dsl.quickSystem 
    "my-computer"              # Name
    "gigabyte-x870e-aorus-elite-wifi7"  # Hardware
    "john";                    # User
  
  # Behind the scenes, this gives you:
  # - Developer workstation preset (security: high, desktop: full, dev: containers)
  # - Performance-optimized settings
  # - All hardware components enabled
  # - User with developer privileges
  
  
  # LEVEL 2: Simple with Preset (Windows "Custom Install")
  # Choose a preset, customize a bit
  
  simple-example = dsl.simpleSystem {
    name = "dev-machine";
    hardware = "gigabyte-x870e-aorus-elite-wifi7";
    preset = "workstation.poweruser";  # Or: workstation.default, laptop.travel, server.secure
    
    # Override just what you need
    overrides = {
      users = [ "alice" "bob" ];
      system.timezone = "America/Denver";
    };
  };
  
  
  # LEVEL 3: Full Control (Power user - like Windows Registry)
  # Full declarative specification when you need it
  
  full-example = with dsl; system "my-workstation" {
    type = workstation;
    purpose = "High-performance development";
    
    hardware = {
      platform = gigabyte.x870e;
      
      # Disable what you don't need
      components = {
        bluetooth.enable = false;  # Save power
      };
    };
    
    capabilities = {
      security = {
        level = high;
        features.yubikey = true;
      };
      
      desktop = {
        type = full;
        terminal = warp-preview;
        editor = vscode;
      };
      
      development = {
        type = full;
        languages = [ "rust" "go" "python" ];
      };
    };
    
    users.alice = {
      role = admin;
      shell = zsh;
    };
    
    system = {
      timezone = "America/Denver";
      
      performance = {
        profile = "performance";
        vm-swappiness = 1;
      };
    };
  };
}
