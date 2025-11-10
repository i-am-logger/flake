{ lib, inputs, nixpkgs }:

rec {
  # Import product builder
  productBuilder = import ./product-builder.nix { inherit lib inputs nixpkgs; };
  
  # Simple system function - no presets, just declarative specs
  system = name: spec:
    productBuilder.buildProduct (spec // { inherit name; });
    
  # Component references - CPU
  amd = {
    ryzen = "amd-ryzen";
    ryzen9 = "amd-ryzen9";
    ryzen9-7950x = "amd-ryzen9-7950x";
    ryzen9-7950x3d = "amd-ryzen9-7950x3d";
    radeon = "amd-radeon";
    radeon780m = "amd-radeon-780m";
  };
  
  intel = {
    xeon = "intel-xeon";
    i9 = "intel-i9";
    i9-13900hx = "intel-i9-13900hx";
  };
  
  # Component references - GPU
  nvidia = {
    rtx4080 = "nvidia-rtx4080";
    rtx4090 = "nvidia-rtx4090";
  };
  
  # Component references - Audio
  realtek = {
    alc4080 = "realtek-alc4080";
  };
  
  # WiFi standards
  wifi4 = "wifi4";
  wifi5 = "wifi5";
  wifi6 = "wifi6";
  wifi6e = "wifi6e";
  wifi7 = "wifi7";
  
  # Ethernet speeds
  "1gbe" = "1gbe";
  "2.5gbe" = "2.5gbe";
  "5gbe" = "5gbe";
  "10gbe" = "10gbe";
  
  # System types
  workstation = "workstation";
  server = "server";
  laptop = "laptop";
  desktop = "desktop";
  
  # User roles
  admin = "admin";
  developer = "developer";
  user = "user";
  
  # Shells
  bash = "bash";
  zsh = "zsh";
  fish = "fish";
  nushell = "nushell";
  
  # Hardware platform shortcuts
  gigabyte = {
    x870e = "gigabyte-x870e-aorus-elite-wifi7";
  };
  
  lenovo = {
    legion16 = "lenovo-legion-16irx8h";
  };
  
  # Generic platforms
  generic-desktop = "generic-desktop";
  generic-server = "generic-server";
}
