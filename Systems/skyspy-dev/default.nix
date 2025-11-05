{ myLib, ... }:

myLib.systems.mkSystem {
  hostname = "skyspy-dev";
  machine = myLib.machines.lenovo-legion-16irx8h;
  users = [ myLib.users.logger ];
  
  stacks = {
    security.enable = true;
    desktop.enable = true;
    cicd = {
      enable = true;
      enableGpu = true;  # NVIDIA RTX 4080 GPU support for runners
      gpuVendor = "nvidia";
    };
  };
  
  config = ../configs/skyspy-dev.nix;
  extraModules = [ ../../hosts/skyspy-dev.nix ];
}
