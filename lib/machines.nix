{ ... }:

{
  gigabyte-x870e-aorus-elite-wifi7 = {
    path = ../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7;
    disko = ../Hardware/motherboards/gigabyte/x870e-aorus-elite-wifi7/disko.nix;
    nixos-hardware = null;
  };
  
  lenovo-legion-16irx8h = {
    path = ../Hardware/motherboards/lenovo/legion-16irx8h;
    disko = null; # skyspy-dev doesn't use disko, uses hardware-configuration.nix
    nixos-hardware = "lenovo-legion-16irx8h"; # 2023 model
  };
}
