# Hardware vs System Analysis

## yoga (Gigabyte X870E AORUS ELITE WIFI7 + AMD)

### HARDWARE → Machines/gigabyte-x870e-aorus-elite-wifi7/
```
drivers/
├── gpu.nix
│   ├── boot.initrd.kernelModules = [ "amdgpu" ]
│   ├── boot.kernelModules = [ "amdgpu" ]
│   ├── boot.kernelParams = [ amdgpu.* ]
│   ├── hardware.graphics config
│   └── hardware.cpu.amd.updateMicrocode
│
├── sound.nix
│   ├── services.pulseaudio.enable = false
│   ├── security.rtkit.enable = true
│   └── services.pipewire (basic driver setup)
│
├── network.nix
│   ├── networking.useDHCP
│   ├── networking.wireless.enable = false
│   ├── hardware.bluetooth.enable = false
│   └── services.hardware.bolt.enable (Thunderbolt)
│
└── boot.nix
    ├── boot.loader config
    ├── boot.kernelPackages
    └── boot.initrd.availableKernelModules

default.nix
├── Import all drivers
└── Hardware scan results
```

### STACKS → Systems/Stacks/
```
audio-tools/
└── alsa-utils, pavucontrol

performance/
├── boot.kernel.sysctl (BBR, memory opts)
├── zramSwap
└── nix-system-ram service
```

### SYSTEM → Systems/yoga/
```
configuration.nix
├── Import Machine (gigabyte hardware)
├── Import Stacks (desktop, security, audio-tools, performance)
├── hostname
├── timezone/locale
├── packages (helix, btop, hyprland, etc)
└── system-specific services
```

---

## skyspy-dev (Lenovo Legion 16IRX8H + Intel/NVIDIA)

### HARDWARE → Machines/lenovo-legion-16irx8h/
```
drivers/
├── gpu.nix
│   ├── boot.kernelModules = [ "kvm-intel" ]
│   ├── hardware.cpu.intel.updateMicrocode
│   └── NVIDIA config (TBD)
│
├── sound.nix
│   ├── services.pulseaudio.enable = false
│   ├── security.rtkit.enable = true
│   ├── services.pipewire (with JACK)
│   └── systemd.services.fix-audio-speaker (hardware fix)
│
├── network.nix
│   ├── networking.useDHCP
│   ├── networking.wireless.enable = false
│   └── services.hardware.bolt.enable
│
├── boot.nix
│   ├── boot.loader config
│   ├── boot.kernelPackages
│   ├── boot.loader.timeout = 2
│   └── boot.initrd.availableKernelModules
│
└── dual-boot.nix (hardware-related)
    ├── time.hardwareClockInLocalTime = true
    ├── boot.supportedFilesystems = [ "ntfs" ]
    └── fileSystems."/home/logger/mnt/windows" (partition mount)

default.nix
├── Import nixos-hardware.nixosModules.lenovo-legion-16irx8h
├── Import all drivers
└── Hardware scan results
```

### STACKS → Systems/Stacks/
```
audio-tools/
└── alsa-utils, pavucontrol, pulseaudio

dual-boot-tools/
└── efibootmgr, gparted, ntfs3g, os-prober, dosfstools, parted

performance/
├── boot.kernel.sysctl
├── zramSwap
└── nix-system-ram service
```

### SYSTEM → Systems/skyspy-dev/
```
configuration.nix
├── Import Machine (lenovo hardware)
├── Import Stacks (desktop, security, audio-tools, dual-boot-tools, performance)
├── Import persistence
├── hostname
├── timezone/locale
├── audit rules (system-specific security policy)
├── systemd.services.audit-rules.enable = false (system quirk)
├── environment.etc."audit/plugins.d/filter.conf" (system config)
├── packages (helix, btop, etc)
└── services (udisks2, timesyncd, fstrim)
```

---

## Key Insights

### Hardware (Machines/)
- **Pure drivers**: Make hardware work, no applications
- **Hardware fixes**: Speaker unmute, clock sync for dual-boot
- **Kernel modules**: GPU, CPU, peripherals
- **Firmware**: Microcode, device firmware

### Stacks
- **Tools**: Applications that use hardware (audio tools, partition tools)
- **Performance**: Optimization that works on any hardware
- **Features**: Dual-boot support, monitoring, etc.

### Systems
- **Identity**: hostname, timezone, locale
- **Policies**: Security rules, audit config
- **Packages**: User software
- **Services**: System-specific services
- **Quirks**: System-specific workarounds
