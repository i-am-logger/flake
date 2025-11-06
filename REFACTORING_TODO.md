# Hardware Refactoring Completion Guide

## Current Status

The hardware refactoring has been initiated with the following structure created:

```
Hardware/
├── README.md
├── audio/realtek/
├── bluetooth/realtek/
├── boot/
├── cpu/amd/
├── cpu/intel/
├── gpu/amd/
├── gpu/nvidia/
├── motherboards/
│   ├── gigabyte/x870e-aorus-elite-wifi7/
│   └── lenovo/legion-16irx8h/
└── network/
```

## What's Been Completed

1. ✅ Hardware modules created under `Hardware/` directory
2. ✅ System definitions updated to reference hardware modules
3. ✅ CI/CD workflows created with self-hosted runner support
4. ✅ Hardware abstraction library (`lib/hardware.nix`)

## What Still Needs to Be Done

### 1. Hardware Module Integration

The System definitions now reference hardware modules, but you should verify:

**yoga system:**
- Uses: `Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7`
- Should import: AMD CPU, AMD GPU, Realtek audio/bluetooth, network

**skyspy-dev system:**
- Uses: `Hardware/motherboards/lenovo/legion-16irx8h`
- Should import: Intel CPU, NVIDIA GPU, Realtek audio/bluetooth, network

### 2. Remove Deprecated Machine References

The `lib/systems.nix` still has deprecated `machine` parameter support. Once all systems are migrated to use `hardware` parameter, you can remove this deprecated code:

```nix
# In lib/systems.nix, remove this section:
++ (lib.optionals (machine != null) [
  # Machine hardware (deprecated approach)
  machine.path
])
++ (lib.optionals (machine != null && machine.disko != null) [
  # Disko partitioning (if machine uses it)
  ...
])
```

### 3. Verify Hardware Module Imports

Each motherboard's `default.nix` should properly import shared hardware modules. Check:

- `Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7/default.nix`
- `Hardware/motherboards/lenovo/legion-16irx8h/default.nix`

They should import modules from:
- `../../../cpu/` (amd or intel)
- `../../../gpu/` (amd or nvidia)
- `../../../audio/realtek`
- `../../../bluetooth/realtek`
- `../../../network`
- `../../../boot`

### 4. Clean Up Old Host Configurations

The `hosts/` directory contains old-style configuration files:
- `hosts/yoga.nix`
- `hosts/skyspy-dev.nix`

These are still being imported via `extraModules` in the system definitions. Consider:
- Moving remaining configuration to appropriate places (Stacks, configs, or Hardware)
- Removing redundant hardware-related configuration

### 5. Disko Integration

If your systems use disko for disk partitioning, ensure:
- Disko configurations exist in Hardware/motherboards/.../disko.nix
- They're properly imported in the hardware module
- The `lib/systems.nix` handles disko imports for hardware modules

### 6. Test Hardware Abstraction

Verify that hardware modules are properly abstracted:
- Can you easily add a new system with similar hardware?
- Are shared components (CPU, GPU, audio) reusable?
- Is hardware-specific configuration separated from system configuration?

## Recommended Next Steps

1. **Test the current changes:**
   ```bash
   # Check flake validity
   nix flake check --dry-run
   
   # Build each system
   nix build .#nixosConfigurations.yoga.config.system.build.toplevel
   nix build .#nixosConfigurations.skyspy-dev.config.system.build.toplevel
   ```

2. **Format all Nix files:**
   ```bash
   # Using alejandra (recommended)
   alejandra .
   
   # Or using nixpkgs-fmt
   find . -name "*.nix" -not -path "*/.*" -exec nixpkgs-fmt {} \;
   ```

3. **Review and consolidate:**
   - Check for duplicate configuration between hosts/ and Hardware/
   - Move hardware-specific items to Hardware/
   - Move system-specific items to Systems/configs/
   - Move reusable features to Systems/Stacks/

4. **Update documentation:**
   - Update HARDWARE_ANALYSIS.md to reflect new structure
   - Document the hardware module system
   - Add examples for adding new systems

5. **Remove deprecated code:**
   - Once all systems use `hardware` parameter, remove `machine` parameter support
   - Clean up unused imports in old host files

## Architecture Benefits

After completion, you'll have:

- **Clear Separation**: Hardware ↔ Systems ↔ Stacks ↔ Config
- **Reusability**: Share CPU, GPU, audio modules across systems
- **Maintainability**: Change hardware drivers in one place
- **Clarity**: Easy to understand what hardware a system uses
- **Extensibility**: Adding new systems is straightforward

## Testing Checklist

- [ ] Both systems build successfully
- [ ] No evaluation errors in flake check
- [ ] Hardware modules are properly imported
- [ ] No duplicate hardware configuration
- [ ] All workflows pass in CI/CD
- [ ] Documentation is updated
