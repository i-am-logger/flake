# System Examples
# Demonstrating declarative product specifications with direct hardware control

{ myLib, pkgs }:

with myLib.dsl;

{
  # Development Workstation with granular hardware control
  dev-workstation = system "dev-workstation" {
    type = workstation;
    purpose = "Software development";
    
    hardware = {
      motherboard = "gigabyte-x870e-aorus-elite-wifi7";
      
      # Direct hardware specification
      cpu = amd.ryzen9-7950x3d;
      gpu = amd.radeon780m;
      audio = true;
      bluetooth = false;  # Disable to save power
      wifi = { enable = true; standard = wifi7; };
      ethernet = { enable = true; speed = "2.5gbe"; };
    };
    
    capabilities = {
      security = {
        firewall.enable = true;
        audit.enable = true;
        secureboot.enable = true;
      };
      
      desktop = {
        terminal = pkgs.warp-terminal;
        editor = pkgs.vscode;
        browser = pkgs.firefox;
      };
      
      development = {
        docker.enable = true;
        languages = {
          rust.enable = true;
          go.enable = true;
          python.enable = true;
        };
      };
    };
    
    users = [ "developer" ];
    
    system = {
      timezone = "America/Denver";
      performance.profile = "performance";
    };
  };
  
  # Travel Laptop - minimal power consumption
  travel-laptop = system "travel-laptop" {
    type = laptop;
    purpose = "Portable computing with maximum battery life";
    
    hardware = {
      motherboard = "lenovo-legion-16irx8h";
      
      # Minimal hardware for battery optimization
      cpu = intel.i9-13900hx;
      gpu = false;  # Disable discrete GPU, use integrated only
      audio = true;
      bluetooth = false;  # Disable for security and battery
      wifi = { enable = true; standard = wifi6e; };
      ethernet = false;  # No ethernet on the go
    };
    
    capabilities = {
      security = {
        firewall.enable = true;
        audit.enable = true;
        secureboot.enable = true;
        yubikey.enable = true;
      };
      
      desktop = {
        terminal = pkgs.alacritty;
        editor = pkgs.helix;
      };
    };
    
    users = [ "traveler" ];
    
    system = {
      timezone = "UTC";
      performance.profile = "powersave";
    };
  };
  
  # Gaming/Creator Workstation - high performance
  gaming-workstation = system "gaming-workstation" {
    type = desktop;
    purpose = "Gaming and content creation";
    
    hardware = {
      motherboard = "gigabyte-x870e-aorus-elite-wifi7";
      
      # Maximum performance hardware
      cpu = amd.ryzen9-7950x;
      gpu = amd.radeon7900xtx;  # Specific high-end GPU model
      audio = { enable = true; model = "realtek-alc4080"; };
      bluetooth = true;
      wifi = { enable = true; standard = wifi7; };
      ethernet = { enable = true; speed = "2.5gbe"; };
    };
    
    capabilities = {
      security = {
        firewall.enable = true;
      };
      
      desktop = {
        terminal = pkgs.alacritty;
        editor = pkgs.vscode;
        browser = pkgs.firefox;
      };
    };
    
    users = [ "gamer" ];
    
    system = {
      timezone = "America/Denver";
      performance.profile = "performance";
    };
  };
  
  # Home Server - headless, minimal hardware
  home-server = system "home-server" {
    type = server;
    purpose = "Home media and file server";
    
    hardware = {
      motherboard = "generic-server";
      
      # Server-optimized: no GUI hardware
      cpu = intel.xeon-silver;
      gpu = false;  # No GPU needed
      audio = false;  # No audio on server
      bluetooth = false;
      wifi = false;  # Wired only for reliability
      ethernet = { enable = true; speed = "10gbe"; };
    };
    
    capabilities = {
      security = {
        firewall.enable = true;
        audit.enable = true;
      };
    };
    
    users.admin = {
      role = admin;
      sshKeys = [ "ssh-ed25519 AAAA..." ];
    };
    
    system.network.firewall.allowedTCPPorts = [ 22 80 443 ];
  };
}
