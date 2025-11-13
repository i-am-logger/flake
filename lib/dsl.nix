{ lib, inputs, nixpkgs }:

rec {
  # Import product builder
  productBuilder = import ./product-builder.nix { inherit lib inputs nixpkgs; };
  
  # Simple system function - no presets, just declarative specs
  system = name: spec:
    productBuilder.buildProduct (spec // { inherit name; });
    
  # Component references - CPU (specific models only)
  amd = {
    # CPUs - specific models
    ryzen9-7950x = "amd-ryzen9-7950x";
    ryzen9-7950x3d = "amd-ryzen9-7950x3d";
    ryzen9-7900x = "amd-ryzen9-7900x";
    ryzen7-7800x3d = "amd-ryzen7-7800x3d";
    ryzen5-7600x = "amd-ryzen5-7600x";
    
    # GPUs - specific models
    radeon780m = "amd-radeon-780m";
    radeon7900xtx = "amd-radeon-7900xtx";
    radeon7900xt = "amd-radeon-7900xt";
    radeon7800xt = "amd-radeon-7800xt";
  };
  
  intel = {
    # CPUs - specific models
    i9-13900hx = "intel-i9-13900hx";
    i9-13900k = "intel-i9-13900k";
    i7-13700k = "intel-i7-13700k";
    i5-13600k = "intel-i5-13600k";
    xeon-e2388g = "intel-xeon-e2388g";
    xeon-silver = "intel-xeon-silver-4314";
  };
  
  # Component references - GPU (NVIDIA specific models)
  nvidia = {
    rtx4090 = "nvidia-rtx4090";
    rtx4080 = "nvidia-rtx4080";
    rtx4070ti = "nvidia-rtx4070ti";
    rtx4060ti = "nvidia-rtx4060ti";
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
