# Example product specification using the product-driven architecture
# Hardware-first declarative system definition

{ myLib, pkgs }:

with myLib.dsl;

system "example-workstation" {
  type = workstation;
  purpose = "Example demonstrating product-driven syntax";
  
  hardware = {
    motherboard = "gigabyte-x870e-aorus-elite-wifi7";
    
    # Direct hardware specification - no nesting
    cpu = amd.ryzen9-7950x3d;
    gpu = amd.radeon780m;
    audio = true;
    bluetooth = false;  # Disable bluetooth
    wifi = { enable = true; standard = wifi7; };
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

