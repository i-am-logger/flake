{ pkgs, lib, ... }:

{
  # Fix various systemd service issues found in boot logs

  # Improve audit system configuration to prevent buffer overflows
  security.audit = {
    enable = true;
    rules = [
      # Reduce audit noise to prevent buffer overflow
      "-a never,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime"
      "-a never,exit -F arch=b32 -S adjtimex -S settimeofday -S clock_settime"
    ];
  };

  # Configure kernel audit buffer settings and hardware fixes
  boot.kernelParams = [
    "audit_backlog_limit=2048" # Increase from default 1024
    "audit=1"
    # Generic hardware fixes
    # (Hardware-specific fixes like TSC, ACPI thermal moved to nixos-hardware)
    # Audio fixes moved to nixos-hardware for Legion-specific configuration
  ];

  # Improve udev rules for better device handling
  services.udev.extraRules = ''
    # Better NVIDIA device handling
    KERNEL=="nvidia*", GROUP="video", MODE="0666"
    KERNEL=="nvidiactl", GROUP="video", MODE="0666"
    
    # Fix X11 socket permissions
    KERNEL=="card[0-9]*", SUBSYSTEM=="drm", GROUP="video", MODE="0666"
  '';

  # Ensure proper service ordering and dependencies
  systemd.services = {
    # Improve NVIDIA services reliability
    nvidia-persistenced = {
      serviceConfig = {
        # Add retry logic
        Restart = lib.mkDefault "on-failure";
        RestartSec = lib.mkDefault "5s";
        # Ensure NVIDIA device nodes exist
        ExecStartPre = "${pkgs.kmod}/bin/modprobe nvidia";
      };
    };

    # Fix audio service ordering
    fix-audio-speaker = {
      after = [ "sound.target" "pipewire.service" "wireplumber.service" ];
      wants = [ "pipewire.service" ];
    };
  };

  # Configure better memory management for large systems
  boot.kernel.sysctl = {
    # Increase virtual memory areas for applications like streamdeck-ui
    "vm.max_map_count" = lib.mkDefault 2147483642;

    # Better memory management
    "vm.swappiness" = lib.mkDefault 10;
    "vm.dirty_ratio" = lib.mkDefault 10;
    "vm.dirty_background_ratio" = lib.mkDefault 5;

    # Improve network performance (allow override by specific configs)
    "net.core.default_qdisc" = lib.mkDefault "fq";
    "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";
  };

  # Enable systemd-oomd for better memory management
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };
}
