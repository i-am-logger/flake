# Hardware Modules

Hardware configuration organized by component type and motherboard specifications.

## Structure

```
Hardware/
├── motherboards/           - Complete motherboard specifications
│   ├── gigabyte/
│   │   └── x870e-aorus-elite-wifi7/
│   └── lenovo/
│       └── legion-16irx8h/
├── cpu/                    - CPU modules by vendor
│   ├── amd.nix
│   └── intel.nix
├── gpu/                    - GPU modules by vendor
│   ├── amd.nix
│   └── nvidia.nix
├── audio/                  - Audio modules by vendor
│   └── realtek.nix
├── bluetooth/              - Bluetooth modules by vendor
│   └── realtek.nix
├── network/
│   └── default.nix
└── boot/
    └── uefi.nix
```

## Usage

Import these modules in motherboard configurations:

```nix
imports = [
  ./drivers/uefi-boot.nix  # Machine-specific boot config
  
  # Shared hardware modules
  ../../../cpu/amd
  ../../../gpu/amd
  ../../../audio/realtek
  ../../../bluetooth/realtek
  ../../../network
];
```
