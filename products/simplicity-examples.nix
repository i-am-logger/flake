# System Examples
# Demonstrating declarative product specifications

{ myLib }:

with myLib.dsl;

{
  # Development Workstation
  dev-workstation = system "dev-workstation" {
    type = workstation;
    purpose = "Software development";
    
    hardware.platform = "gigabyte-x870e-aorus-elite-wifi7";
    
    capabilities = {
      security.level = high;
      desktop = {
        type = full;
        terminal = warp;
        editor = vscode;
      };
      development = {
        type = containers;
        languages = [ "rust" "go" "python" ];
      };
    };
    
    users = [ "developer" ];
    
    system = {
      timezone = "America/Denver";
      performance.profile = "performance";
    };
  };
  
  # Travel Laptop
  travel-laptop = system "travel-laptop" {
    type = laptop;
    purpose = "Portable computing with maximum security";
    
    hardware = {
      platform = "lenovo-legion-16irx8h";
      components.bluetooth.enable = false;  # Save battery
    };
    
    capabilities = {
      security.level = maximum;
      desktop = {
        type = minimal;
        terminal = alacritty;
        editor = helix;
      };
    };
    
    users = [ "traveler" ];
    
    system = {
      timezone = "UTC";
      performance.profile = "powersave";
    };
  };
  
  # Home Server
  home-server = system "home-server" {
    type = server;
    purpose = "Home media and file server";
    
    hardware.platform = "generic-server";
    
    capabilities.security.level = high;
    
    users.admin = {
      role = admin;
      sshKeys = [ "ssh-ed25519 AAAA..." ];
    };
    
    system.network.firewall.allowedTCPPorts = [ 22 80 443 ];
  };
}
