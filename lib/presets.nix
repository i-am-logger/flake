{ lib, inputs, nixpkgs }:

rec {
  # Import product builder
  productBuilder = import ./product-builder.nix { inherit lib inputs nixpkgs; };
  
  # Presets - Opinionated configurations that can be referenced in system
  presets = {
    # Workstation presets
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
    
    # Server presets
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
    
    # Laptop presets
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
}
