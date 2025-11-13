{ myLib }:

with myLib.dsl;

system "yoga" {
  type = workstation;
  purpose = "High-performance development and CI/CD workstation";
  
  hardware = {
    motherboard = "gigabyte-x870e-aorus-elite-wifi7";
    
    # Specific hardware components - AMD Ryzen 9 7950X3D platform
    cpu = amd.ryzen9-7950x3d;
    gpu = amd.radeon780m;  # Integrated graphics
    audio = true;
    bluetooth = true;
    wifi = { enable = true; standard = wifi7; };
    ethernet = { enable = true; speed = "2.5gbe"; };
  };
  
  capabilities = {
    security = {
      firewall.enable = true;
      secureBoot.enable = true;
      yubikey.enable = true;
      audit.enable = false;
    };
    
    desktop = {
      warp.enable = true;
      warp.preview = true;
      vscode.enable = true;
      browser.enable = true;
    };
    
    development = {
      docker.enable = true;
      kubernetes.enable = false;
      languages = [ "rust" "go" "python" "nix" ];
    };
    
    cicd = {
      githubRunner.enable = true;
      gpuSupport.enable = true;  # AMD Radeon GPU support for runners
    };
  };
  
  users = [ "logger" ];
  
  system = {
    timezone = "America/Denver";
    locale = "en_US.UTF-8";
    performance.profile = "performance";
  };
}
