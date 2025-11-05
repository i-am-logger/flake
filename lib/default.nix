{ inputs, lib, nixpkgs, ... }:

{
  systems = import ./systems.nix { inherit inputs lib nixpkgs; };
  machines = import ./machines.nix { };
  users = import ./users.nix { };
}
