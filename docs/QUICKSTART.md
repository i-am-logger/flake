# Quick Start Guide
## Building Your First Product-Driven NixOS System

This guide gets you started with the product-driven architecture in 15 minutes.

---

## Prerequisites

- NixOS or Nix package manager installed
- Basic understanding of Nix language
- Git for cloning the repository

---

## 1. Understanding the Concept (2 minutes)

### Traditional Approach
```nix
# You configure HOW to build
imports = [ ./module1.nix ./module2.nix ];
services.foo.enable = true;
services.bar.config = "...";
```

### Product Approach
```nix
# You declare WHAT you want
system "my-system" {
  type = workstation;
  capabilities.desktop.type = "full";
  capabilities.security.level = "high";
}
```

**Key Difference:** Product specs describe the **system**, not the **build process**.

---

## 2. Quick Examples (5 minutes)

### Example 1: Minimal Desktop

```nix
# products/minimal-desktop.nix
{ dsl }:

with dsl;

system "minimal-desktop" {
  type = workstation;
  
  hardware.platform = generic-desktop;
  
  capabilities {
    desktop.type = "minimal";  # Terminal + editor only
    security.level = "medium";
  }
  
  users = [ "alice" ];
}
```

**What you get:**
- Basic desktop environment
- Terminal (alacritty) + editor (helix)
- Firewall + basic security
- User account for alice

### Example 2: Development Workstation

```nix
# products/dev-workstation.nix
{ dsl }:

with dsl;

system "dev-workstation" {
  type = workstation;
  purpose = "Full-stack development";
  
  hardware.platform = gigabyte.x870e;
  
  capabilities {
    security.level = "high";
    
    desktop {
      type = "full";
      terminal = "warp";
      editor = "vscode";
    }
    
    development {
      type = "full";
      languages = [ "rust" "go" "python" "typescript" ];
      containers = true;
      orchestration = true;
    }
  }
  
  users.bob = {
    role = developer;
    shell = zsh;
  };
  
  system.timezone = "America/Denver";
}
```

**What you get:**
- Secure desktop with Warp + VSCode
- Docker + Kubernetes
- Rust, Go, Python, TypeScript toolchains
- Developer user with zsh
- Mountain time zone

### Example 3: CI/CD Server

```nix
# products/ci-server.nix
{ dsl }:

with dsl;

system "ci-server" {
  type = server;
  purpose = "Continuous Integration and Deployment";
  
  hardware.platform = generic-server;
  
  capabilities {
    security.level = "maximum";
    
    cicd {
      enabled = true;
      runner.type = "github-actions";
      runner.count = 4;
      registry.enable = true;
    }
    
    observability {
      enable = true;
      metrics.prometheus = true;
      logging.loki = true;
    }
  }
  
  users.admin = {
    role = admin;
    sshKeys = [ "ssh-ed25519 AAAA..." ];
  };
  
  system {
    network.firewall = {
      allowedTCPPorts = [ 22 443 ];
    };
  }
}
```

**What you get:**
- Hardened server configuration
- 4 GitHub Actions runners
- Container registry
- Prometheus + Loki monitoring
- Admin access via SSH

---

## 3. Hardware Selection (2 minutes)

### Available Platforms

```nix
# Desktop motherboards
hardware.platform = gigabyte.x870e;          # AMD Ryzen, Radeon, WiFi 7
hardware.platform = asus.rog-strix;          # Intel, NVIDIA

# Laptop motherboards  
hardware.platform = lenovo.legion16;         # Intel i9, RTX 4080
hardware.platform = framework.laptop13;      # Modular laptop

# Generic platforms
hardware.platform = generic-desktop;         # Standard desktop
hardware.platform = generic-server;          # Standard server
```

### Component Control

```nix
# Disable components you don't need
hardware.platform = gigabyte.x870e {
  components = {
    bluetooth.enable = false;  # Don't need Bluetooth
    wifi.enable = false;       # Using ethernet only
  };
};
```

### Component Details

```nix
# Specify exact components
hardware.platform = custom-build {
  components = {
    cpu = amd.ryzen9-7950x;
    gpu = nvidia.rtx4090;
    wifi = wifi7;
    ethernet = 10gbe;
  };
};
```

---

## 4. Capabilities & Presets (3 minutes)

### Security Levels

```nix
capabilities.security.level = "none";     # No extra security
capabilities.security.level = "low";      # Firewall only
capabilities.security.level = "medium";   # Firewall + audit
capabilities.security.level = "high";     # + Secure boot
capabilities.security.level = "maximum";  # All security features
```

### Desktop Types

```nix
capabilities.desktop.type = "minimal";    # Terminal + editor
capabilities.desktop.type = "standard";   # + Browser
capabilities.desktop.type = "full";       # + Office suite
```

### Development Types

```nix
capabilities.development.type = "basic";      # Git + languages
capabilities.development.type = "containers"; # + Docker
capabilities.development.type = "full";       # + Kubernetes
```

### Custom Capabilities

```nix
capabilities {
  security {
    level = "high";
    features.yubikey = true;    # Override: add YubiKey
    features.audit = false;     # Override: disable audit
  }
  
  desktop {
    type = "standard";
    terminal = "warp-preview";  # Override: use preview version
  }
}
```

---

## 5. Users & Roles (2 minutes)

### Simple User

```nix
users = [ "alice" ];
```

### User with Role

```nix
users.bob = {
  role = developer;  # Adds to docker, libvirt groups
  shell = zsh;
};
```

### User with Preferences

```nix
users.charlie = {
  role = admin;      # Adds to wheel, networkmanager groups
  shell = fish;
  
  preferences = {
    terminal = "warp";
    editor = "vscode";
  };
  
  applications = [
    "slack"
    "1password"
    "spotify"
  ];
};
```

### Multiple Users

```nix
users = {
  alice = { role = admin; shell = zsh; };
  bob = { role = developer; shell = bash; };
  charlie = { role = user; shell = fish; };
};
```

---

## 6. System Configuration (1 minute)

### Basic System Settings

```nix
system {
  hostname = "my-system";        # Will be set from system name
  timezone = "America/New_York";
  locale = "en_US.UTF-8";
}
```

### Network Configuration

```nix
system.network = {
  manager = "networkmanager";    # or "systemd-networkd"
  wireless.enable = true;
  firewall.allowedTCPPorts = [ 80 443 ];
};
```

### Performance Tuning

```nix
system.performance = {
  profile = "performance";       # or "balanced" or "powersave"
  cpu.governor = "performance";
  memory.swappiness = 1;
};
```

### Storage

```nix
system.storage = {
  persistence = {
    enable = true;
    root = "tmpfs";              # Ephemeral root
    persist = [
      "/var/log"
      "/var/lib"
      "/home"
    ];
  };
  
  encryption = {
    enable = true;
    method = "luks";
  };
};
```

---

## 7. Build & Deploy (2 minutes)

### Build Configuration

```bash
# Build the system
nix build .#nixosConfigurations.my-system.config.system.build.toplevel

# Build installer ISO
nix build .#nixosConfigurations.installer-iso.config.system.build.isoImage
```

### Deploy to System

```bash
# Switch to new configuration
sudo nixos-rebuild switch --flake .#my-system

# Test without switching
sudo nixos-rebuild test --flake .#my-system

# Build VM for testing
nixos-rebuild build-vm --flake .#my-system
./result/bin/run-my-system-vm
```

### Update flake.nix

```nix
{
  outputs = { self, nixpkgs, ... }@inputs:
    let
      dsl = import ./lib/dsl.nix { lib = nixpkgs.lib; };
    in
    {
      nixosConfigurations = {
        my-system = import ./products/my-system.nix { inherit dsl; };
      };
    };
}
```

---

## 8. Common Patterns

### Gaming PC

```nix
system "gaming-rig" {
  type = desktop;
  
  hardware.platform = custom {
    components = {
      cpu = amd.ryzen9-7950x3d;
      gpu = nvidia.rtx4090;
    };
  };
  
  capabilities {
    gaming = {
      enable = true;
      platform = "steam";
      vr = true;
    };
    
    desktop {
      type = "full";
      terminal = "alacritty";
    };
  };
  
  system.performance.profile = "performance";
}
```

### Home Server

```nix
system "home-server" {
  type = server;
  
  hardware.platform = generic-server;
  
  capabilities {
    security.level = "high";
    
    services = {
      nas = true;
      media-server = "plex";
      backup = true;
    };
  };
  
  users.admin = {
    role = admin;
    sshKeys = [ "..." ];
  };
}
```

### Laptop for Travel

```nix
system "travel-laptop" {
  type = laptop;
  
  hardware.platform = framework.laptop13 {
    components = {
      bluetooth.enable = false;  # Save battery
    };
  };
  
  capabilities {
    security.level = "maximum";  # Public WiFi protection
    desktop.type = "minimal";     # Save resources
  };
  
  system.performance.profile = "powersave";
}
```

---

## 9. Tips & Best Practices

### Start Simple

```nix
# Don't do this on day 1:
system "complex" {
  hardware.platform = custom {
    components = {
      # 50 lines of components...
    };
  };
  capabilities = {
    # 100 lines of capabilities...
  };
}

# Do this instead:
system "simple" {
  hardware.platform = generic-desktop;
  capabilities.desktop.type = "standard";
  users = [ "me" ];
}
```

### Use Presets

```nix
# Prefer presets:
capabilities.security.level = "high";

# Over manual configuration:
capabilities.security = {
  firewall.enable = true;
  secureboot.enable = true;
  audit.enable = true;
  # ...
};
```

### Iterate

1. Start with minimal configuration
2. Test in VM
3. Add one capability at a time
4. Test each addition
5. Document what you learn

### Read the Schemas

```bash
# See all available options
nix eval .#nixosConfigurations.my-system.options.capabilities --json | jq
```

---

## 10. Getting Help

### Documentation

- `ARCHITECTURE.md` - Complete architecture specification
- `IMPLEMENTATION.md` - Implementation details
- `SYNTAX_COMPARISON.md` - Old vs new syntax examples

### Examples

- `products/yoga.nix` - High-performance workstation
- `products/skyspy-dev.nix` - Development laptop
- `products/ci-server.nix` - CI/CD server

### Common Issues

**Issue:** "Unknown hardware platform"
```nix
# Make sure platform is in catalog
hardware.platform = "gigabyte-x870e";  # ✗ Wrong format
hardware.platform = gigabyte.x870e;    # ✓ Correct
```

**Issue:** "Component not available"
```nix
# Check what components the platform has
# in Hardware/motherboards/<vendor>/<model>/default.nix
```

**Issue:** "Capability not found"
```nix
# Check Capabilities/ directory for available capabilities
# or Systems/Stacks/ for stack implementations
```

---

## Next Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/i-am-logger/flake.git
   cd flake
   ```

2. **Review example products**
   ```bash
   cat products/yoga.nix
   cat products/skyspy-dev.nix
   ```

3. **Create your product**
   ```bash
   cp products/yoga.nix products/my-system.nix
   editor products/my-system.nix
   ```

4. **Test in VM**
   ```bash
   nixos-rebuild build-vm --flake .#my-system
   ./result/bin/run-my-system-vm
   ```

5. **Deploy**
   ```bash
   sudo nixos-rebuild switch --flake .#my-system
   ```

---

## Conclusion

The product-driven architecture makes NixOS configuration:
- **Simpler** - Less code, clearer intent
- **Safer** - Type-checked, validated
- **Faster** - Presets for common configs
- **Better** - Self-documenting, maintainable

**Welcome to product-driven NixOS!** 🎉
