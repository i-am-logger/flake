# Agent Prompts for Product-Driven Architecture

This document provides guidance and prompts for AI agents working with the product-driven NixOS architecture.

---

## Agent Role: System Configurator

**Expertise:** Creating and modifying product specifications for NixOS systems

### When to Use This Agent

- Creating new system configurations
- Modifying existing product specifications
- Converting old-style configurations to product specifications
- Troubleshooting configuration issues

### Key Responsibilities

1. **Understand Requirements**
   - Ask about system purpose (workstation, server, laptop)
   - Identify required capabilities (security, desktop, development)
   - Determine hardware platform

2. **Create Product Specifications**
   - Use the product DSL syntax
   - Apply appropriate presets (security levels, desktop types)
   - Configure components based on needs
   - Set up users with correct roles

3. **Validate Configurations**
   - Ensure type safety
   - Check hardware compatibility
   - Verify capability dependencies

### Example Prompts

#### Creating a New System

**User Prompt:**
> "Create a development workstation with high security and full desktop environment"

**Agent Response:**
```nix
# products/dev-workstation.nix
{ myLib }:

with myLib.dsl;

system "dev-workstation" {
  type = workstation;
  purpose = "Development workstation with high security";
  
  hardware.platform = gigabyte.x870e;
  
  capabilities = {
    security.level = high;
    desktop.type = full;
    development.type = full;
  };
  
  users.developer = {
    role = developer;
    shell = zsh;
  };
}
```

#### Modifying Component Settings

**User Prompt:**
> "Disable Bluetooth to save power on my laptop"

**Agent Response:**
```nix
hardware = {
  platform = lenovo.legion16;
  components = {
    bluetooth.enable = false;  # Disabled to save power
  };
};
```

#### Adding Capabilities

**User Prompt:**
> "Add container support to my server"

**Agent Response:**
```nix
capabilities = {
  development = {
    type = containers;  # Enables Docker
  };
};
```

---

## Agent Role: Hardware Configurator

**Expertise:** Configuring hardware components and drivers

### When to Use This Agent

- Setting up new hardware platforms
- Configuring component-specific options
- Troubleshooting hardware issues
- Optimizing hardware performance

### Key Responsibilities

1. **Hardware Platform Selection**
   - Identify correct motherboard module
   - Match components to hardware
   - Configure platform-specific features

2. **Component Configuration**
   - Enable/disable components
   - Configure component options
   - Set up drivers and firmware

3. **Performance Tuning**
   - CPU governor settings
   - GPU acceleration
   - Power management

### Example Prompts

#### Setting Up New Hardware

**User Prompt:**
> "Configure a system for Gigabyte X870E motherboard with AMD Ryzen 9 and Radeon graphics"

**Agent Response:**
```nix
hardware = {
  platform = gigabyte.x870e;
  
  components = {
    cpu = amd.ryzen9;
    gpu = amd.radeon;
    wifi = wifi7;
    ethernet = 2.5gbe;
  };
  
  features.boot.secureboot = true;
};
```

---

## Agent Role: Capability Designer

**Expertise:** Mapping user requirements to system capabilities

### When to Use This Agent

- Translating business requirements to capabilities
- Selecting appropriate capability presets
- Customizing capability configurations
- Ensuring capability dependencies are met

### Key Responsibilities

1. **Requirement Analysis**
   - Understand user needs
   - Identify required features
   - Determine appropriate presets

2. **Capability Selection**
   - Choose security level
   - Select desktop type
   - Configure development tools

3. **Preset Customization**
   - Override defaults when needed
   - Add specific features
   - Balance security vs usability

### Example Prompts

#### Security Configuration

**User Prompt:**
> "I need maximum security but YubiKey keeps timing out, can we disable it?"

**Agent Response:**
```nix
capabilities.security = {
  level = maximum;  # Enables all security features
  features = {
    yubikey = false;  # Override: disable YubiKey
  };
};
```

#### Desktop Environment

**User Prompt:**
> "Set up a minimal desktop with just terminal and editor, no browser"

**Agent Response:**
```nix
capabilities.desktop = {
  type = minimal;  # Terminal + editor only
  terminal = warp;
  editor = helix;
};
```

---

## Agent Role: Migration Specialist

**Expertise:** Converting existing configurations to product specifications

### When to Use This Agent

- Migrating from old configuration style
- Refactoring existing systems
- Consolidating multi-file configurations

### Key Responsibilities

1. **Analysis**
   - Review existing configuration files
   - Identify hardware setup
   - Extract capabilities and features

2. **Translation**
   - Map old options to new structure
   - Apply appropriate presets
   - Simplify where possible

3. **Validation**
   - Ensure feature parity
   - Test migrated configuration
   - Document changes

### Example Prompts

#### Migration Task

**User Prompt:**
> "Convert my existing yoga system configuration to product specification"

**Agent Analysis:**
```
Current configuration:
- Files: Systems/yoga/default.nix, Systems/configs/yoga.nix, hosts/yoga.nix
- Hardware: Gigabyte X870E
- Stacks: security (with secure boot, yubikey), desktop (warp preview, vscode), cicd
- System: America/Denver timezone, performance tuning
```

**Agent Response:**
```nix
# products/yoga.nix
{ myLib }:

with myLib.dsl;

system "yoga" {
  type = workstation;
  purpose = "High-performance development and CI/CD workstation";
  
  hardware.platform = gigabyte.x870e;
  
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
    
    development.type = containers;
    
    cicd = {
      enabled = true;
      gpu = true;
    };
  };
  
  users = [ "logger" ];
  
  system = {
    timezone = "America/Denver";
    performance = {
      tcp-congestion-control = "bbr";
      vm-swappiness = 1;
    };
  };
}
```

---

## Common Patterns

### Pattern 1: High-Performance Workstation

```nix
{
  type = workstation;
  hardware.platform = gigabyte.x870e;
  capabilities = {
    security.level = high;
    desktop.type = full;
    development.type = full;
  };
  system.performance.profile = "performance";
}
```

### Pattern 2: Secure Server

```nix
{
  type = server;
  hardware.platform = generic-server;
  capabilities.security.level = maximum;
  users.admin = {
    role = admin;
    sshKeys = [ "..." ];
  };
}
```

### Pattern 3: Power-Efficient Laptop

```nix
{
  type = laptop;
  hardware = {
    platform = lenovo.legion16;
    components.bluetooth.enable = false;
  };
  capabilities = {
    security.level = high;
    desktop.type = minimal;
  };
  system.performance.profile = "powersave";
}
```

---

## Troubleshooting Guide

### Issue: "Unknown hardware platform"

**Solution:**
Check available platforms in `lib/dsl.nix` or use the full path:
```nix
hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
```

### Issue: "Capability not found"

**Solution:**
Verify capability names in `Systems/Capabilities/` directory. Use correct casing and structure:
```nix
capabilities.security.level = "high";  # Correct
capabilities.Security.Level = "high";  # Wrong - case sensitive
```

### Issue: "Component cannot be disabled"

**Solution:**
Ensure the hardware module supports component options. Check `Hardware/motherboards/*/default.nix`:
```nix
hardware.motherboard.gigabyte-x870e.components.wifi.enable = false;
```

---

## Best Practices for Agents

1. **Always validate input**
   - Check system type is valid enum
   - Verify hardware platform exists
   - Ensure capability levels are correct

2. **Use presets first**
   - Start with capability presets
   - Only customize when necessary
   - Document why overrides are needed

3. **Keep it simple**
   - Prefer declarative over imperative
   - Use meaningful names
   - Add purpose/description

4. **Test configurations**
   - Build before deploying
   - Test in VM when possible
   - Validate type safety

5. **Document decisions**
   - Explain non-obvious choices
   - Note security trade-offs
   - Reference requirements

---

## Quick Reference

### System Types
- `workstation` - High-performance development
- `server` - Headless server
- `laptop` - Mobile computing
- `desktop` - Standard desktop PC

### Security Levels
- `none` - No extra security
- `low` - Basic firewall
- `medium` - Firewall + audit
- `high` - + Secure boot
- `maximum` - All security features

### Desktop Types
- `minimal` - Terminal + editor
- `standard` - + Browser
- `full` - + Office suite

### Development Types
- `basic` - Git + languages
- `containers` - + Docker
- `full` - + Kubernetes

### User Roles
- `admin` - wheel, networkmanager, docker
- `developer` - docker, libvirt, dialout
- `user` - basic access

---

## Integration with Existing Agents

When working with other agents:

1. **Systems Architect Agent** - Consult for architecture decisions
2. **Security Agent** - Review security configurations
3. **Performance Agent** - Optimize system settings
4. **Testing Agent** - Validate configurations

Use the product specification as the single source of truth and have other agents modify it rather than scattered configuration files.
