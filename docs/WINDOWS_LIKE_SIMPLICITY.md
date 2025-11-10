# Windows-like Configuration Philosophy
## Simple, Opinionated, Overridable

This document explains how the product-driven architecture achieves Windows-like simplicity while maintaining the power and flexibility of Nix.

---

## Philosophy: Progressive Disclosure

Like Windows, the architecture provides **progressive levels of complexity** using a **single unified interface**:

1. **Beginner** - Use presets (Windows installer with defaults)
2. **Intermediate** - Preset + custom overrides (Windows settings app)
3. **Advanced** - Full explicit configuration (Windows registry/group policy)

All use the same `system` function - you just specify more or less detail.

---

## Single System Function

**Everything uses `system`** - no need to learn different functions:

```nix
with dsl;

system "name" {
  # Start simple with a preset, or go full control - your choice
}
```

---

## Level 1: Simple with Preset (Beginner)

**Windows equivalent:** Click "Next" with default settings

**Minimal configuration using opinionated preset:**

```nix
{ myLib }:

with myLib.dsl;

system "my-computer" {
  preset = "workstation.developer";
  
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  users = [ "john" ];
}
```

**What the preset provides automatically:**
- ✅ type = workstation
- ✅ Security level = high
- ✅ Full desktop environment (terminal, editor, browser)
- ✅ Development tools (Docker, containers)
- ✅ Performance-optimized settings
- ✅ Sane defaults for everything

**Like Windows:** Opinionated defaults that just work.

---

## Level 2: Preset with Overrides (Intermediate)

**Windows equivalent:** Settings app - change what you want

**Start with a preset, customize specific parts:**

### Available Presets

#### Workstation Presets
```nix
"workstation.default"    # Standard workstation (medium security, standard desktop)
"workstation.developer"  # Development workstation (high security, full desktop, containers)
"workstation.poweruser"  # All features enabled (high security, full desktop, full dev)
```

#### Server Presets
```nix
"server.default"         # Standard server (high security, headless)
"server.secure"          # Maximum security server
```

#### Laptop Presets
```nix
"laptop.default"         # Balanced laptop (high security, standard desktop)
"laptop.travel"          # Battery + security optimized (maximum security, minimal desktop, powersave)
```

### Example: Customized Laptop

```nix
with dsl;

system "travel-laptop" {
  preset = "laptop.travel";  # Start with travel preset
  
  hardware.platform = "lenovo-legion-16irx8h";
  users = [ "alice" ];
  
  # Override specific preset defaults
  capabilities.desktop.terminal = alacritty;  # Prefer lighter terminal
  system.timezone = "Europe/London";
}
```

**Like Windows Settings:** Choose from presets, override what you need.

---

## Level 3: Full Control (Advanced)

**Windows equivalent:** Registry Editor, Group Policy, PowerShell

**Complete explicit specification without preset:**

```nix
with dsl;

system "custom-workstation" {
  type = workstation;
  
  hardware = {
    platform = gigabyte.x870e;
    components = {
      bluetooth.enable = false;  # Don't need it
      wifi.enable = false;       # Ethernet only
    };
  };
  
  capabilities = {
    security = {
      level = maximum;
      features = {
        secureboot = true;
        yubikey = true;
        apparmor = true;
      };
    };
    
    desktop = {
      type = full;
      terminal = warp-preview;
      editor = vscode;
    };
    
    development = {
      type = full;
      languages = [ "rust" "go" "python" "typescript" ];
      containers = true;
      orchestration = true;
    };
  };
  
  users.admin = {
    role = admin;
    shell = zsh;
    applications = [ "slack" "1password" ];
  };
  
  system = {
    timezone = "America/Denver";
    
    performance = {
      profile = "performance";
      tcp-congestion-control = "bbr";
      vm-swappiness = 1;
    };
    
    storage.persistence = {
      enable = true;
      root = "tmpfs";
    };
  };
}
```

**Like Windows Registry:** Every setting available, full control.

---

## Opinionated Defaults (The Windows Way)

### What "Opinionated" Means

**Good defaults that work for 90% of users:**

1. **Security:** High by default (like Windows Defender)
2. **Desktop:** Full featured by default (like Windows UI)
3. **Performance:** Balanced by default (like Windows power plan)
4. **Hardware:** All components enabled by default (like Windows drivers)

### What "Overridable" Means

**Change anything when you need to:**

```nix
with dsl;

system "custom" {
  preset = "workstation.developer";  # Start with preset
  
  # Override specific parts
  capabilities.security.level = maximum;  # More security
  hardware.components.bluetooth.enable = false;  # Less power usage
}
```

**Like Windows:** Change display settings, disable services, customize everything.

---

## Preset Comparison

### Workstation.Default
**For:** Office users, students
```
Security:    Medium   (Firewall + basic protection)
Desktop:     Standard (Terminal + editor + browser)
Development: Basic    (Git + languages)
Performance: Balanced
```

### Workstation.Developer
**For:** Software developers
```
Security:    High       (Firewall + audit + secureboot)
Desktop:     Full       (Terminal + editor + browser + office)
Development: Containers (Docker + languages)
Performance: Performance
```

### Workstation.Poweruser
**For:** Advanced users, system administrators
```
Security:    High (Firewall + audit + secureboot)
Desktop:     Full (All applications)
Development: Full (Docker + Kubernetes + all languages)
Performance: Performance
```

### Server.Default
**For:** General servers
```
Security:    High     (Hardened configuration)
Desktop:     None     (Headless)
Development: None     (Server only)
Performance: Balanced
```

### Server.Secure
**For:** Production servers, sensitive data
```
Security:  Maximum   (All security features)
Desktop:   None      (Headless)
Dev:       None      (Server only)
Performance: Balanced
```

### Laptop.Default
**For:** Daily driver laptop
```
Security:  High      (Public WiFi protection)
Desktop:   Standard  (Essential applications)
Dev:       Basic     (Light development)
Performance: Balanced (Battery + performance)
```

### Laptop.Travel
**For:** Travel, public places
```
Security:  Maximum   (Maximum protection)
Desktop:   Minimal   (Lightweight, battery efficient)
Dev:       None      (No dev tools to reduce attack surface)
Performance: Powersave (Maximum battery life)
```

---

## Migration Path: From Complex to Simple

### Before (Complex - 3 files, 100+ lines)

```nix
# Systems/yoga/default.nix
myLib.systems.mkSystem {
  hostname = "yoga";
  hardware = [ ../../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7 ];
  stacks = {
    security = { enable = true; secureBoot.enable = true; yubikey.enable = true; };
    desktop = { enable = true; warp.enable = true; vscode.enable = true; };
    cicd = { enable = true; enableGpu = true; };
  };
  config = ../configs/yoga.nix;
  extraModules = [ ../../hosts/yoga.nix ];
}

# + Systems/configs/yoga.nix (50 lines)
# + hosts/yoga.nix (30 lines)
```

### After (Simple - 1 file, ~10 lines)

```nix
# products/yoga.nix
{ myLib }:

with myLib.dsl;

system "yoga" {
  preset = "workstation.poweruser";
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  users = [ "logger" ];
  system.timezone = "America/Denver";
}
```

**90% code reduction**, same functionality!

---

## Common Use Cases

### Use Case 1: New Developer Laptop

```nix
with dsl;

system "dev-laptop" {
  preset = "workstation.developer";
  hardware.platform = "lenovo-legion-16irx8h";
  users = [ "alice" ];
}
```

### Use Case 2: Home Server

```nix
with dsl;

system "home-server" {
  preset = "server.default";
  hardware.platform = "generic-server";
  users.admin.sshKeys = [ "ssh-ed25519 AAA..." ];
}
```

**Result:** Secure server with SSH access only.

### Use Case 3: Gaming PC

```nix
with dsl;

system "gaming-rig" {
  preset = "workstation.default";
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  users = [ "gamer" ];
  
  # Add gaming capability
  capabilities.gaming = {
    enable = true;
    platform = "steam";
  };
  
  system.performance.profile = "performance";
}
```

**Result:** Gaming PC with Steam, performance mode, standard security.

### Use Case 4: Maximum Security Workstation

```nix
with dsl;

system "secure-workstation" {
  preset = "workstation.poweruser";
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  
  # Override for maximum security
  capabilities.security = {
    level = maximum;
    features = {
      secureboot = true;
      yubikey = true;
      apparmor = true;
      audit = true;
    };
  };
}
```

**Result:** Hardened workstation with all security features.

---

## Why This Works (Like Windows)

### 1. Single Unified Interface

```
Everyone uses 'system' - no multiple functions to learn
  ↓
Add preset for simplicity, or skip for full control
  ↓
Same syntax, different detail levels
```

**Like Windows:** One installer, one Settings app - just different levels of customization.

### 2. Progressive Detail

```
Simple:       system with preset → minimal config
              ↓
Intermediate: system with preset + overrides → customize specifics
              ↓
Advanced:     system without preset → full declarative spec
```

**Like Windows:** Default install → Settings customization → Registry tweaking.

### 3. Sensible Defaults

- Security is ON by default (not off)
- Common tools are included
- Performance is balanced
- Everything works out of the box

**Like Windows:** Defender enabled, drivers installed, sound works.

### 4. Easy Customization

Change one thing without understanding everything:

```nix
with dsl;

system "my-system" {
  preset = "workstation.developer";
  capabilities.desktop.terminal = alacritty;  # Just change this
}
```

**Like Windows:** Change wallpaper without knowing DirectX.

### 5. Discoverable Options

IDE autocomplete shows available presets:
- `workstation.default`
- `workstation.developer`
- `workstation.poweruser`

**Like Windows:** Settings app shows all options.

### 6. Validation & Safety

Type checking prevents mistakes:

```nix
preset = "workstation.devloper"  # ✗ Typo caught!
preset = "workstation.developer"  # ✓ Correct
```

**Like Windows:** Can't set invalid values in Settings.

---

## For Windows Admins

If you're coming from Windows system administration:

| Windows Concept | NixOS Equivalent |
|----------------|------------------|
| Default Install | `system` with preset |
| Settings App | `system` with preset + overrides |
| Group Policy | `system` with full config |
| Registry | Full declarative specification |
| Windows Edition (Home/Pro) | Presets (default/developer/poweruser) |
| OEM Installation | Hardware platform specification |
| User Profiles | User roles (admin/developer/user) |
| Windows Update | `nixos-rebuild switch` |
| Safe Mode | Boot previous generation |

---

## Best Practices

### 1. Start Simple

```nix
# Day 1: Use a preset
with dsl;

system "my-pc" {
  preset = "workstation.developer";
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  users = [ "me" ];
}
```

### 2. Add Customization When Needed

```nix
# Day 30: Override specific settings
with dsl;

system "my-pc" {
  preset = "workstation.developer";
  hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
  users = [ "me" ];
  
  # Add more security
  capabilities.security.level = maximum;
}
```

### 3. Go Full Control Only When Necessary

```nix
# Month 3: Custom requirements
with dsl;

system "my-pc" {
  # Full specification without preset
  type = workstation;
  hardware.platform = gigabyte.x870e;
  # ... complete custom config
}
```

### 4. Use Presets as Learning Tools

```nix
# See what a preset includes, then customize
with dsl;

system "custom" {
  preset = "workstation.poweruser";  # Start here
  
  # Override just what you need
  capabilities.desktop.terminal = alacritty;
}
```

---

## Conclusion

The product-driven architecture achieves **Windows-like simplicity**:

✅ **Works out of the box** - Default configurations that just work
✅ **Easy to customize** - Change one thing without understanding everything  
✅ **Opinionated defaults** - Smart choices for 90% of use cases
✅ **Fully overridable** - Power users can control everything
✅ **Progressive complexity** - Learn as you grow

**The goal:** As easy as Windows for beginners, as powerful as Nix for experts.

**Remember:** The simpler you start, the easier it is to maintain!
