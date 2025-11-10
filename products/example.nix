# Example product specification using the product-driven architecture
# Hardware-first declarative system definition
#
# Motherboards declare compatible components via arrays:
#   compatibleCpus = [ amd.ryzen9-7950x3d amd.ryzen9-7950x ... ]
#   compatibleGpus = [ amd.radeon7900xtx nvidia.rtx4080 ... ]
#   supportedWifi = [ wifi7 wifi6e ... ]
#   supportedEthernet = [ "2.5gbe" "1gbe" ]
#
# Users select from compatible options when configuring their system.

{ myLib, pkgs }:

with myLib.dsl;

system "example-workstation" {
  type = workstation;
  purpose = "Example demonstrating product-driven syntax";
  
  hardware = {
    motherboard = "gigabyte-x870e-aorus-elite-wifi7";
    
    # Direct hardware specification - choose from motherboard's compatible list
    # Gigabyte X870E supports AM5 CPUs: Ryzen 9 7950X3D, 7950X, 7900X, Ryzen 7 7800X3D, etc.
    cpu = amd.ryzen9-7950x3d;
    
    # Compatible GPUs: AMD Radeon 7900 XTX/XT, 7800 XT, NVIDIA RTX 40 series
    gpu = amd.radeon780m;
    
    audio = true;
    bluetooth = false;  # Disable bluetooth
    
    # WiFi 7 is supported by this motherboard (also supports WiFi 6E, 6, 5, 4)
    wifi = { enable = true; standard = wifi7; };
    
    # 2.5GbE Ethernet is supported (also supports 1GbE)
    ethernet = { enable = true; speed = "2.5gbe"; };
  };
  
  capabilities = {
    # Security - explicit options instead of opinionated levels
    security = {
      firewall.enable = true;
      audit.enable = true;
      secureboot.enable = true;
      yubikey.enable = true;
    };
    
    # Desktop - direct package references
    desktop = {
      terminal = pkgs.warp-terminal;
      editor = pkgs.vscode;
      browser = pkgs.firefox;
    };
    
    # Development - explicit features
    development = {
      docker.enable = true;
      podman.enable = false;
      languages = {
        rust.enable = true;
        go.enable = true;
        python.enable = true;
      };
    };
  };
  
  users = [ "logger" ];
  
  system = {
    timezone = "America/Denver";
    locale = "en_US.UTF-8";
    
    network = {
      manager = "networkmanager";
      wireless = false;
    };
    
    performance = {
      tcp-congestion-control = "bbr";
      vm-swappiness = 1;
    };
  };
}

