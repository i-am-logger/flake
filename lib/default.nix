{ inputs, lib, nixpkgs, ... }:

{
  systems = import ./systems.nix { inherit inputs lib nixpkgs; };
  hardware = import ./hardware.nix { };
  users = import ./users.nix { };
  
  # Product-driven architecture
  types = import ./types.nix { inherit lib; };
  productBuilder = import ./product-builder.nix { inherit inputs lib nixpkgs; };
  dsl = import ./dsl.nix { inherit lib inputs nixpkgs; };
}
