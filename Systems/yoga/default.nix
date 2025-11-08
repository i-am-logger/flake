{ myLib, ... }:

myLib.systems.mkSystem {
  hostname = "yoga";
  users = [ myLib.users.logger ];
  
  # Hardware configuration
  hardware = [
    ../../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7
  ];
  
  stacks = {
    security = {
      enable = true;
      secureBoot.enable = true;
      yubikey.enable = true;
      auditRules.enable = false;
    };
    desktop = {
      enable = true;
      warp.enable = true;
      warp.preview = true;
      vscode.enable = true;
      browser.enable = true;
    };
    cicd = {
      enable = true;
      enableGpu = true;  # AMD Radeon GPU support for runners
    };
  };
  
  config = ../configs/yoga.nix;
  extraModules = [ ../../hosts/yoga.nix ];
}
