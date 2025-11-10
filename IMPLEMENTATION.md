# Implementation Guide
## Product-Driven Architecture Implementation

This guide provides step-by-step instructions for implementing the product-driven architecture defined in `ARCHITECTURE.md`.

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

#### 1.1 Create Type System

**File:** `lib/types.nix`

```nix
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
```

#### 1.2 Create Product Builder

**File:** `lib/product-builder.nix`

```nix
{ inputs, lib, nixpkgs, ... }:

let
  productTypes = import ./types.nix { inherit lib; };
in

{
  # Main builder function
  buildProduct = productSpec:
    let
      # Validate product specification
      validated = validateProduct productSpec;
      
      # Translate to system configuration
      systemConfig = translateProduct validated;
      
      # Build NixOS system
      nixosSystem = lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = systemConfig.modules;
      };
    in
    nixosSystem;
    
  # Validation
  validateProduct = spec:
    let
      checks = {
        hasName = builtins.hasAttr "name" spec;
        hasHardware = builtins.hasAttr "hardware" spec;
        hasType = builtins.hasAttr "type" spec;
      };
      
      errors = lib.filter (check: !checks.${check}) (builtins.attrNames checks);
    in
    if (builtins.length errors) > 0
    then throw "Product validation failed: ${builtins.toString errors}"
    else spec;
    
  # Translation from product spec to NixOS modules
  translateProduct = spec: {
    modules = [
      # Hardware modules
      (translateHardware spec.hardware)
      
      # Capability modules  
      (translateCapabilities spec.capabilities or {})
      
      # User modules
      (translateUsers spec.users or [])
      
      # UI modules
      (translateUI spec.ui or {})
      
      # System modules
      (translateSystem spec.system or {})
      
      # Base configuration
      {
        networking.hostName = spec.name;
        system.stateVersion = "24.05";
      }
    ];
  };
  
  translateHardware = hwSpec: {
    # Enable the specified motherboard
    hardware.motherboard.${hwSpec.platform}.enable = true;
    
    # Apply component overrides if specified
    hardware.motherboard.${hwSpec.platform}.components =
      hwSpec.components or {};
  };
  
  translateCapabilities = capSpec: {
    # Map capabilities to stacks
    capabilities = capSpec;
  };
  
  translateUsers = users: {
    users.users = builtins.listToAttrs (map (user:
      { name = user; value = { isNormalUser = true; }; }
    ) users);
  };
  
  translateUI = uiSpec: {
    ui = uiSpec;
  };
  
  translateSystem = sysSpec: {
    time.timeZone = sysSpec.timezone or "UTC";
    i18n.defaultLocale = sysSpec.locale or "en_US.UTF-8";
  };
}
```

### Phase 2: Hardware Layer (Weeks 3-4)

#### 2.1 Refactor Motherboard Modules

**Template:** `Hardware/motherboards/{vendor}/{model}/default.nix`

```nix
{ config, lib, pkgs, modulesPath, ... }:

with lib;

let
  # Unique identifier for this motherboard
  mbId = "vendor-model";
  cfg = config.hardware.motherboard.${mbId};
in

{
  options.hardware.motherboard.${mbId} = {
    enable = mkEnableOption "${mbId} motherboard";
    
    components = {
      cpu = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable CPU support";
        };
        vendor = mkOption {
          type = types.enum [ "amd" "intel" ];
          default = "amd";  # or "intel"
          description = "CPU vendor";
        };
      };
      
      gpu = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GPU support";
        };
        vendor = mkOption {
          type = types.enum [ "amd" "nvidia" "intel" ];
          default = "amd";  # or appropriate default
          description = "GPU vendor";
        };
        type = mkOption {
          type = types.enum [ "integrated" "discrete" ];
          default = "integrated";
          description = "GPU type";
        };
      };
      
      audio = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audio chipset";
        };
      };
      
      bluetooth = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Bluetooth";
        };
      };
      
      wifi = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable WiFi";
        };
        standard = mkOption {
          type = types.enum [ "wifi4" "wifi5" "wifi6" "wifi6e" "wifi7" ];
          default = "wifi6";
          description = "WiFi standard";
        };
      };
      
      ethernet = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Ethernet";
        };
        speed = mkOption {
          type = types.enum [ "1gbe" "2.5gbe" "5gbe" "10gbe" ];
          default = "1gbe";
          description = "Ethernet speed";
        };
      };
    };
    
    features = {
      boot = {
        type = mkOption {
          type = types.enum [ "uefi" "bios" ];
          default = "uefi";
          description = "Boot type";
        };
        secureboot = mkOption {
          type = types.bool;
          default = true;
          description = "Secure boot capability";
        };
      };
    };
  };
  
  config = mkIf cfg.enable (mkMerge [
    # Base configuration
    {
      imports = [
        ./hardware-configuration.nix
        ./drivers/uefi-boot.nix
      ];
      
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    }
    
    # CPU
    (mkIf cfg.components.cpu.enable {
      imports = [
        (if cfg.components.cpu.vendor == "amd"
         then ../../../cpu/amd
         else ../../../cpu/intel)
      ];
    })
    
    # GPU
    (mkIf cfg.components.gpu.enable {
      imports = [
        (if cfg.components.gpu.vendor == "amd"
         then ../../../gpu/amd
         else if cfg.components.gpu.vendor == "nvidia"
         then ../../../gpu/nvidia
         else ../../../gpu/intel)
      ];
    })
    
    # Audio
    (mkIf cfg.components.audio.enable {
      imports = [ ../../../audio/realtek ];
    })
    
    # Bluetooth
    (mkIf cfg.components.bluetooth.enable {
      imports = [ ../../../bluetooth/realtek ];
    })
    
    # Network
    (mkIf (cfg.components.wifi.enable || cfg.components.ethernet.enable) {
      imports = [ ../../../network ];
    })
    
    # Boot
    {
      imports = [ ../../../boot ];
      hardware.boot.secure = cfg.features.boot.secureboot;
    }
  ]);
}
```

#### 2.2 Create Hardware Component Modules

**Example:** `Hardware/cpu/amd/default.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # AMD CPU configuration
  boot.kernelModules = [ "kvm-amd" ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
  
  # AMD-specific optimizations
  boot.kernelParams = [ "amd_pstate=active" ];
}
```

**Example:** `Hardware/gpu/amd/default.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # AMD GPU configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # ROCm for compute
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];
}
```

### Phase 3: Stack Layer (Weeks 5-6)

#### 3.1 Create Capability Module

**File:** `Systems/Capabilities/default.nix`

```nix
{ config, lib, ... }:

{
  imports = [
    ./security.nix
    ./desktop.nix
    ./development.nix
    ./gaming.nix
    ./media.nix
    ./networking.nix
  ];
}
```

#### 3.2 Implement Capability to Stack Translation

**Example:** `Systems/Capabilities/security.nix`

```nix
{ config, lib, ... }:

with lib;

let
  cfg = config.capabilities.security;
  
  # Security level presets
  levelPresets = {
    none = {
      stacks.security.enable = false;
    };
    
    low = {
      stacks.security = {
        enable = true;
        firewall.enable = true;
      };
    };
    
    medium = {
      stacks.security = {
        enable = true;
        firewall.enable = true;
        audit.enable = true;
      };
    };
    
    high = {
      stacks.security = {
        enable = true;
        firewall.enable = true;
        audit.enable = true;
        secureboot.enable = true;
      };
    };
    
    maximum = {
      stacks.security = {
        enable = true;
        firewall = {
          enable = true;
          strict = true;
        };
        audit.enable = true;
        secureboot.enable = true;
        apparmor.enable = true;
      };
    };
  };
in

{
  options.capabilities.security = {
    level = mkOption {
      type = types.enum [ "none" "low" "medium" "high" "maximum" ];
      default = "medium";
      description = "Security level preset";
    };
    
    features = mkOption {
      type = types.attrsOf types.bool;
      default = {};
      description = "Override specific security features";
    };
  };
  
  config = mkMerge [
    # Apply level preset
    (levelPresets.${cfg.level})
    
    # Apply feature overrides
    (mkIf (cfg.features != {}) {
      stacks.security = mkMerge [
        (mkIf (cfg.features.secureboot or false) {
          secureboot.enable = true;
        })
        (mkIf (cfg.features.yubikey or false) {
          yubikey.enable = true;
        })
        (mkIf (cfg.features.apparmor or false) {
          apparmor.enable = true;
        })
        (mkIf (cfg.features.audit or false) {
          audit.enable = true;
        })
      ];
    })
  ];
}
```

### Phase 4: Product DSL (Weeks 7-8)

#### 4.1 Create DSL Parser

**File:** `lib/dsl.nix`

```nix
{ lib }:

rec {
  # system "name" { ... }
  system = name: spec:
    let
      productBuilder = import ./product-builder.nix { inherit lib; };
    in
    productBuilder.buildProduct (spec // { inherit name; });
    
  # Component references
  amd = {
    ryzen = "amd-ryzen";
    ryzen9-7950x = "amd-ryzen9-7950x";
    radeon = "amd-radeon";
    radeon780m = "amd-radeon-780m";
  };
  
  intel = {
    xeon = "intel-xeon";
    i9-13900hx = "intel-i9-13900hx";
  };
  
  nvidia = {
    rtx4080 = "nvidia-rtx4080";
  };
  
  realtek = {
    alc4080 = "realtek-alc4080";
  };
  
  # WiFi standards
  wifi4 = "wifi4";
  wifi5 = "wifi5";
  wifi6 = "wifi6";
  wifi6e = "wifi6e";
  wifi7 = "wifi7";
  
  # Ethernet speeds
  "1gbe" = "1gbe";
  "2.5gbe" = "2.5gbe";
  "5gbe" = "5gbe";
  "10gbe" = "10gbe";
  
  # Hardware platform shortcuts
  gigabyte.x870e = "gigabyte-x870e";
  lenovo.legion16 = "lenovo-legion-16irx8h";
  
  # Security levels
  security-levels = {
    none = "none";
    low = "low";
    medium = "medium";
    high = "high";
    maximum = "maximum";
  };
}
```

#### 4.2 Update flake.nix

```nix
{
  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
      
      # Import DSL
      dsl = import ./lib/dsl.nix { inherit lib; };
      
      # Import product specifications
      products = {
        yoga = import ./products/yoga.nix { inherit dsl; };
        skyspy-dev = import ./products/skyspy-dev.nix { inherit dsl; };
      };
    in
    {
      nixosConfigurations = products;
    };
}
```

### Phase 5: Migration (Weeks 9-10)

#### 5.1 Migration Checklist

- [ ] Backup existing configurations
- [ ] Create product specifications for existing systems
- [ ] Test product specifications in VM
- [ ] Gradually migrate one system at a time
- [ ] Validate all features work
- [ ] Update documentation

#### 5.2 Migration Tool

**File:** `scripts/migrate-to-product.sh`

```bash
#!/usr/bin/env bash
# Migrate existing system to product specification

SYSTEM=$1

if [ -z "$SYSTEM" ]; then
  echo "Usage: $0 <system-name>"
  exit 1
fi

echo "Migrating $SYSTEM to product specification..."

# Create products directory if it doesn't exist
mkdir -p products

# Generate product specification from existing config
cat > "products/${SYSTEM}.nix" <<EOF
# Product specification for ${SYSTEM}
# Generated on $(date)

{ dsl }:

with dsl;

system "${SYSTEM}" {
  type = workstation;  # FIXME: Set appropriate type
  purpose = "TODO: Add system purpose";
  
  hardware = {
    platform = "TODO";  # FIXME: Set motherboard
    components = {
      # FIXME: Configure components
    };
  };
  
  capabilities = {
    # FIXME: Configure capabilities
  };
  
  users = [ ];  # FIXME: Add users
  
  system = {
    timezone = "UTC";  # FIXME: Set timezone
    locale = "en_US.UTF-8";
  };
}
EOF

echo "Created products/${SYSTEM}.nix"
echo "Please review and update the FIXME items"
```

---

## Testing Strategy

### Unit Tests

Test individual components:

```nix
# tests/hardware/motherboard.nix
{ pkgs, lib }:

let
  eval = lib.evalModules {
    modules = [
      ../../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7
      {
        hardware.motherboard.gigabyte-x870e = {
          enable = true;
          components.wifi.enable = false;
        };
      }
    ];
  };
in

assert eval.config.hardware.motherboard.gigabyte-x870e.components.wifi.enable == false;
assert eval.config.hardware.motherboard.gigabyte-x870e.components.cpu.enable == true;

pkgs.runCommand "test-passed" {} "echo success > $out"
```

### Integration Tests

Test complete product builds:

```nix
# tests/products/yoga.nix
{ pkgs }:

let
  yoga = import ../../products/yoga.nix;
in

pkgs.nixosTest {
  name = "yoga-product-test";
  
  nodes.machine = yoga;
  
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("test -f /etc/hostname")
    machine.succeed("hostname | grep -q yoga")
  '';
}
```

---

## Rollout Plan

### Week 1-2: Foundation
- Implement type system
- Create product builder
- Set up basic validation

### Week 3-4: Hardware
- Refactor gigabyte-x870e motherboard
- Refactor lenovo-legion motherboard
- Test hardware modules

### Week 5-6: Capabilities
- Implement security capability
- Implement desktop capability
- Implement development capability

### Week 7-8: DSL
- Create DSL parser
- Update flake.nix
- Create example products

### Week 9-10: Migration
- Migrate yoga system
- Migrate skyspy-dev system
- Update documentation

### Week 11-12: Polish
- Add validation CLI
- Improve error messages
- Create user guide

---

## Success Criteria

- [ ] All existing systems work with new architecture
- [ ] Product specifications are more readable
- [ ] Hardware components are reusable
- [ ] Adding new systems is straightforward
- [ ] Documentation is complete
- [ ] All tests pass

