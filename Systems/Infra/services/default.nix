{ config, lib, pkgs, ... }:

{
  imports = [
    ./k3s.nix
    # Future services go here
  ];
}
