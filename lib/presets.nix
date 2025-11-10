# Product Presets - Windows-like Simplicity
## Opinionated Defaults with Override Capability

{ lib, inputs, nixpkgs }:

rec {
  # Import core builder
  productBuilder = import ./product-builder.nix { inherit lib inputs nixpkgs; };
  
  # Presets - Opinionated system configurations (Windows-like simplicity)
  presets = {
    # Workstation presets - Full development environments
    workstation = {
      default = {
        type = "workstation";
        capabilities = {
          security.level = "medium";
          desktop.type = "standard";
          development.type = "basic";
        };
        system = {
          performance.profile = "balanced";
        };
      };
      
      developer = {
        type = "workstation";
        capabilities = {
          security.level = "high";
          desktop.type = "full";
          development.type = "containers";
        };
        system = {
          performance.profile = "performance";
        };
      };
      
      poweruser = {
        type = "workstation";
        capabilities = {
          security.level = "high";
          desktop.type = "full";
          development.type = "full";
        };
        system = {
          performance.profile = "performance";
        };
      };
    };
    
    # Server presets - Headless systems
    server = {
      default = {
        type = "server";
        capabilities = {
          security.level = "high";
        };
        system = {
          performance.profile = "balanced";
        };
      };
      
      secure = {
        type = "server";
        capabilities = {
          security.level = "maximum";
        };
        system = {
          performance.profile = "balanced";
        };
      };
    };
    
    # Laptop presets - Mobile computing
    laptop = {
      default = {
        type = "laptop";
        capabilities = {
          security.level = "high";
          desktop.type = "standard";
        };
        system = {
          performance.profile = "balanced";
        };
      };
      
      travel = {
        type = "laptop";
        capabilities = {
          security.level = "maximum";
          desktop.type = "minimal";
        };
        system = {
          performance.profile = "powersave";
        };
      };
    };
  };
  
  # Simple system builder - Just name, hardware, and optional overrides
  simpleSystem = { name, hardware, preset ? "workstation.default", overrides ? {} }:
    let
      # Get the preset configuration
      presetPath = lib.splitString "." preset;
      presetConfig = lib.getAttrFromPath presetPath presets;
      
      # Merge preset with overrides (overrides win)
      finalConfig = lib.recursiveUpdate presetConfig overrides;
      
      # Add hardware
      configWithHardware = finalConfig // {
        inherit name;
        hardware = { platform = hardware; };
      };
    in
    productBuilder.buildProduct configWithHardware;
  
  # Ultra-simple system - Just 3 parameters
  quickSystem = name: hardware: users:
    simpleSystem {
      inherit name hardware;
      preset = "workstation.developer";
      overrides = {
        users = if builtins.isList users then users else [ users ];
      };
    };
}
