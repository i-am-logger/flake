{
  description = "My Personal NixOS ricing";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hypr-contrib.url = "github:hyprwm/contrib";

    stylix.url = "github:danth/stylix";
  };

  outputs = inputs @ { self, nixpkgs, flake-utils, ... }:
    let
      lib = nixpkgs.lib;
      user = "snick";
    in
    {
      nixosConfigurations = {
        handlink = lib.nixosSystem {
          pkgs = import nixpkgs {
            system = "x86_64-linux";        
            config.allowUnfree = true; # Allow proprietary software
          };
          
          specialArgs = { inherit nixpkgs self inputs user; };
          modules = [
            (./handlink)
          ];
        };
        
        #bumblebee = {
        #  system = "x86_64-linux";
        #  # specialArgs = { inherit nixpkgs self inputs user; };
        #  modules = [
        #    ./bumblebee/configuration.nix
        #  ];
        #};
      }; 
    };
}
