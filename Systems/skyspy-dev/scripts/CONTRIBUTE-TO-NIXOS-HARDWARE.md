# Contributing Audio Fix to nixos-hardware

## 🎯 **Issue Found**

The current `nixos-hardware` configuration for **Lenovo Legion Pro 7 16IRX8H** is missing an important audio fix. The speakers don't work out of the box without this kernel module parameter.

## 🔧 **The Fix**

Add this to the Legion Pro 7 16IRX8H configuration:

```nix
# Audio fix for Legion Pro 7 16IRX8H - force specific codec model  
# This fixes the audio issue where speakers don't work out of the box
boot.extraModprobeConfig = ''
  options snd-hda-intel model=lenovo-legion-7i
'';
```

## 📋 **How to Contribute**

### 1. **Fork nixos-hardware**
```bash
# Go to https://github.com/NixOS/nixos-hardware
# Click "Fork" button
```

### 2. **Clone your fork**
```bash
git clone https://github.com/YOUR-USERNAME/nixos-hardware.git
cd nixos-hardware
```

### 3. **Create a branch**
```bash
git checkout -b fix-legion-pro-7-16irx8h-audio
```

### 4. **Edit the file**
Edit `lenovo/legion/16irx8h/default.nix` and add the audio fix:

```nix
{
  lib,
  config,
  ...
}:
{
  imports = [
    ../../../common/cpu/intel
    ../../../common/gpu/nvidia/prime.nix
    ../../../common/gpu/nvidia/ada-lovelace
    ../../../common/pc/laptop
    ../../../common/pc/ssd
    ../../../common/hidpi.nix
  ];

  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.lenovo-legion-module
    config.boot.kernelPackages.nvidia_x11
  ];

  # Audio fix for Legion Pro 7 16IRX8H - force specific codec model
  # This fixes the audio issue where speakers don't work out of the box
  boot.extraModprobeConfig = ''
    options snd-hda-intel model=lenovo-legion-7i
  '';

  hardware = {
    nvidia = {
      modesetting.enable = lib.mkDefault true;
      powerManagement.enable = lib.mkDefault true;
      #
      prime = {
        intelBusId = "PCI:00:02:0";
        nvidiaBusId = "PCI:01:00:0";
      };
    };
  };

  # Cooling management
  services.thermald.enable = lib.mkDefault true;

  # √(2560² + 1600²) px / 16 in ≃ 189 dpi
  services.xserver.dpi = 189;
}
```

### 5. **Commit the changes**
```bash
git add lenovo/legion/16irx8h/default.nix
git commit -m "lenovo/legion/16irx8h: add audio fix for speaker support

The speakers on Legion Pro 7 16IRX8H don't work without forcing
the lenovo-legion-7i codec model for snd-hda-intel.

This adds the necessary kernel module parameter to make audio
work out of the box for this laptop model."
```

### 6. **Push and create PR**
```bash
git push origin fix-legion-pro-7-16irx8h-audio
```

Then go to GitHub and create a Pull Request.

## 📝 **PR Description Template**

```markdown
## Description

Fixes audio support for Lenovo Legion Pro 7 16IRX8H by adding the required kernel module parameter.

## Problem

The speakers on this laptop model don't work out of the box. Audio only works through headphones, but built-in speakers remain silent.

## Solution

Added `options snd-hda-intel model=lenovo-legion-7i` to force the correct codec model for the audio hardware.

## Testing

- [x] Tested on Lenovo Legion Pro 7 16IRX8H
- [x] Speakers now work after applying this fix
- [x] Headphone audio continues to work
- [x] System audio controls work properly

## Hardware Details

- **Model**: Lenovo Legion Pro 7 16IRX8H  
- **Audio**: Realtek ALC287 (requires lenovo-legion-7i model)
- **NixOS Version**: 25.05
```

## 🎉 **Benefits for the Community**

This fix will help all Legion Pro 7 16IRX8H users get working audio out of the box, instead of having to discover and manually add this fix themselves.

## ✅ **After Contributing**

Once your PR is merged, you can:

1. **Remove the local audio fix** from your `/etc/nixos/configuration.nix` (already done)
2. **Update nixos-hardware** to get the upstream fix
3. **Help other users** who have the same laptop model

The fix will be available to all NixOS users with this laptop model! 🚀
