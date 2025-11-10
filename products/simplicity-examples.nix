# Unified System Examples
# All use the same 'system' function, with optional preset support

{ myLib }:

let
  dsl = myLib.dsl;
in

{
  # SIMPLE: Minimal configuration with preset
  # Preset handles all the complexity
  
  minimal-workstation = with dsl; system "my-workstation" {
    preset = "workstation.developer";
    hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
    users = [ "john" ];
  };
  
  # Behind the scenes, preset provides:
  # - type = workstation
  # - security.level = high
  # - desktop.type = full
  # - development.type = containers
  # - performance.profile = performance
  
  
  # CUSTOMIZED: Preset with specific overrides
  # Start with preset, change what you need
  
  custom-laptop = with dsl; system "travel-laptop" {
    preset = "laptop.travel";  # Maximum security + battery optimization
    
    hardware.platform = "lenovo-legion-16irx8h";
    users = [ "alice" ];
    
    # Override preset defaults
    capabilities.desktop.terminal = alacritty;  # Lighter than default
    system.timezone = "America/Denver";
  };
  
  
  # FULL CONTROL: No preset, explicit configuration
  # When you need complete control
  
  custom-workstation = with dsl; system "my-custom-workstation" {
    type = workstation;
    purpose = "High-performance development";
    
    hardware = {
      platform = "gigabyte-x870e-aorus-elite-wifi7";
      
      # Disable components you don't need
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
