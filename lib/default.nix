{ inputs, lib, nixpkgs, ... }:

{
  systems = import ./systems.nix { inherit inputs lib nixpkgs; };
  hardware = import ./hardware.nix { };
  users = import ./users.nix { };
}
