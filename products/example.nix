# Example product specification using the product-driven architecture
# Simple, declarative system definition

{ myLib }:

with myLib.dsl;

system "example-workstation" {
  type = workstation;
  purpose = "Example demonstrating product-driven syntax";
  
  hardware = {
    platform = "gigabyte-x870e-aorus-elite-wifi7";
    
    # Component control (optional)
    components = {
      # All components enabled by default
      # Can disable specific ones:
      # bluetooth.enable = false;
    };
  };
  
  capabilities = {
    security = {
      level = high;
      features.yubikey = true;
    };
    
    desktop = {
      type = full;
      terminal = warp;
      editor = vscode;
    };
    
    development = {
      type = containers;
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

