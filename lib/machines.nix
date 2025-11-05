{ ... }:

{
  gigabyte-x870e-aorus-elite-wifi7 = {
    path = ../Machines/gigabyte-x870e-aorus-elite-wifi7;
    disko = ../Machines/gigabyte-x870e-aorus-elite-wifi7/disko.nix;
    nixos-hardware = null;
  };
  
  lenovo-legion-16irx8h = {
    path = ../Machines/lenovo-legion-16irx8h;
    disko = null; # skyspy-dev doesn't use disko, uses hardware-configuration.nix
    nixos-hardware = "lenovo-legion-16irx8h"; # 2023 model
  };
}
