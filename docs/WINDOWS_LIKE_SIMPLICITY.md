# Windows-like Configuration Philosophy
## Simple, Opinionated, Overridable

This document explains how the product-driven architecture achieves Windows-like simplicity while maintaining the power and flexibility of Nix.

---

## Philosophy: Progressive Disclosure

Like Windows, the architecture provides **three levels of complexity**:

1. **Beginner** - Works out of the box (Windows installer)
2. **Intermediate** - Choose presets, tweak settings (Windows settings app)
3. **Advanced** - Full control over every detail (Windows registry/group policy)

Users start simple and only learn complexity when they need it.

---

## Level 1: Ultra-Simple (Beginner)

**Windows equivalent:** Click "Next" through the installer

**3 parameters:** Name, Hardware, User

```nix
{ myLib }:

dsl.quickSystem 
  "my-computer"              # Computer name
  "gigabyte-x870e-aorus-elite-wifi7"  # What's inside
  "john";                    # Who uses it
```

**What you get automatically:**
- ✅ Secure workstation (high security)
- ✅ Full desktop environment (terminal, editor, browser, office)
- ✅ Development tools (containers, languages)
- ✅ Optimized performance
- ✅ User with developer privileges
- ✅ Sane defaults for everything

**Like Windows:** It just works. No configuration needed.

---

## Level 2: Simple with Presets (Intermediate)

**Windows equivalent:** Customize settings during install, Settings app

**Choose a preset, override what you need**

### Available Presets

#### Workstation Presets
```nix
"workstation.default"    # Standard workstation
"workstation.developer"  # Development workstation (default)
"workstation.poweruser"  # All features enabled
```

#### Server Presets
```nix
"server.default"         # Standard server
"server.secure"          # Maximum security server
```

#### Laptop Presets
```nix
"laptop.default"         # Balanced laptop
"laptop.travel"          # Battery-optimized, maximum security
```

### Example: Laptop for Travel

```nix
dsl.simpleSystem {
  name = "travel-laptop";
  hardware = "lenovo-legion-16irx8h";
  preset = "laptop.travel";
  
  # Override just what you need
  overrides = {
    users = [ "alice" ];
    capabilities.desktop.terminal = "alacritty";  # Prefer lighter terminal
  };
};
```

**Like Windows Settings:** Choose from presets, customize specific things.

---

## Level 3: Full Control (Advanced)

**Windows equivalent:** Registry Editor, Group Policy, PowerShell

**Complete declarative specification**

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
# Start with a preset
preset = "workstation.developer";

# Override specific parts
overrides = {
  capabilities.security.level = "maximum";  # More security
  hardware.components.bluetooth.enable = false;  # Less power usage
};
```

**Like Windows:** Change display settings, disable services, customize everything.

---

## Preset Comparison

### Workstation.Default
**For:** Office users, students
```
Security:  Medium    (Firewall + basic protection)
Desktop:   Standard  (Terminal + editor + browser)
Dev:       Basic     (Git + languages)
Performance: Balanced
```

### Workstation.Developer (Default for quickSystem)
**For:** Software developers
```
Security:  High      (Firewall + audit + secureboot)
Desktop:   Full      (Terminal + editor + browser + office)
Dev:       Containers (Docker + languages)
Performance: Performance
```

### Workstation.Poweruser
**For:** Advanced users, system administrators
```
Security:  High      (Firewall + audit + secureboot)
Desktop:   Full      (All applications)
Dev:       Full      (Docker + Kubernetes + all languages)
Performance: Performance
```

### Server.Default
**For:** General servers
```
Security:  High      (Hardened configuration)
Desktop:   None      (Headless)
Dev:       None      (Server only)
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

### After (Simple - 1 file, 8 lines)

```nix
# products/yoga.nix
{ myLib }:

myLib.dsl.simpleSystem {
  name = "yoga";
  hardware = "gigabyte-x870e-aorus-elite-wifi7";
  preset = "workstation.poweruser";
  overrides.users = [ "logger" ];
}
```

**Or even simpler (3 lines):**

```nix
{ myLib }:

myLib.dsl.quickSystem "yoga" "gigabyte-x870e-aorus-elite-wifi7" "logger"
```

---

## Common Use Cases

### Use Case 1: New Developer Laptop

```nix
dsl.quickSystem "dev-laptop" "lenovo-legion-16irx8h" "alice"
```

**Result:** Ready-to-code laptop with Docker, VSCode, all languages, high security.

### Use Case 2: Home Server

```nix
dsl.simpleSystem {
  name = "home-server";
  hardware = "generic-server";
  preset = "server.default";
  overrides.users.admin.sshKeys = [ "ssh-ed25519 AAA..." ];
}
```

**Result:** Secure server with SSH access only.

### Use Case 3: Gaming PC

```nix
dsl.simpleSystem {
  name = "gaming-rig";
  hardware = "gigabyte-x870e-aorus-elite-wifi7";
  preset = "workstation.default";
  overrides = {
    users = [ "gamer" ];
    capabilities.gaming = {
      enable = true;
      platform = "steam";
    };
    system.performance.profile = "performance";
  };
}
```

**Result:** Gaming PC with Steam, performance mode, standard security.

### Use Case 4: Maximum Security Workstation

```nix
dsl.simpleSystem {
  name = "secure-workstation";
  hardware = "gigabyte-x870e-aorus-elite-wifi7";
  preset = "workstation.poweruser";
  overrides = {
    capabilities.security = {
      level = "maximum";
      features = {
        secureboot = true;
        yubikey = true;
        apparmor = true;
        audit = true;
      };
    };
  };
}
```

**Result:** Hardened workstation with all security features.

---

## Why This Works (Like Windows)

### 1. Progressive Learning Curve

```
Beginner:     quickSystem → 3 parameters
              ↓
Intermediate: simpleSystem → preset + overrides  
              ↓
Advanced:     system → full declarative spec
```

**Like Windows:** Start with installer, move to Settings, advance to Registry.

### 2. Sensible Defaults

- Security is ON by default (not off)
- Common tools are included
- Performance is balanced
- Everything works out of the box

**Like Windows:** Defender enabled, drivers installed, sound works.

### 3. Easy Customization

Change one thing without understanding everything:

```nix
overrides.capabilities.desktop.terminal = "alacritty"
```

**Like Windows:** Change wallpaper without knowing DirectX.

### 4. Discoverable Options

IDE autocomplete shows available presets:
- `workstation.default`
- `workstation.developer`
- `workstation.poweruser`

**Like Windows:** Settings app shows all options.

### 5. Validation & Safety

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
| Windows Installer | `quickSystem` |
| Settings App | `simpleSystem` with presets |
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
# Day 1: Just get it working
quickSystem "my-pc" "gigabyte-x870e-aorus-elite-wifi7" "me"
```

### 2. Add Complexity When Needed

```nix
# Day 30: Need more security
simpleSystem {
  name = "my-pc";
  hardware = "gigabyte-x870e-aorus-elite-wifi7";
  preset = "workstation.developer";
  overrides.capabilities.security.level = "maximum";
}
```

### 3. Go Full Control Only When Necessary

```nix
# Month 3: Custom requirements
system "my-pc" {
  # Full specification
}
```

### 4. Use Presets as Templates

```nix
# Learn from presets, customize from there
preset = "workstation.poweruser";
overrides = {
  # Your specific changes
};
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
