# Example product specification using the new DSL
# This demonstrates the product-driven syntax

{ myLib }:

let
  dsl = myLib.dsl;
in

with dsl;

system "example-workstation" {
  type = workstation;
  purpose = "Example system to demonstrate product-driven architecture";
  
  hardware = {
    platform = "gigabyte-x870e-aorus-elite-wifi7";
    
    # Component overrides (optional)
    components = {
      # All components enabled by default
      # Can disable specific ones:
      # bluetooth.enable = false;
    };
  };
  
  capabilities = {
    security = {
      level = high;
    };
    
    desktop = {
      type = standard;
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
