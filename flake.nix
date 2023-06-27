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

  outputs = inputs @ { self, nixpkgs, flake-utils, hyprland, hypr-contrib, stylix, ... }:
    let
      lib = nixpkgs.lib;
      user = "snick";
      pkgs = import nixpkgs {
        system = "x86_64-linux";        
        config.allowUnfree = true; # Allow proprietary software
      };
    in
    {
      nixosConfigurations = {
        handlink = lib.nixosSystem {
          
          specialArgs = { inherit pkgs self inputs user; };
          modules = [
            (modules/oct-motd)
            hyprland.nixosModules.default
            { programs.hyprland.enable = true; }
            ./hosts/handlink.nix
            stylix.nixosModules.stylix 
            Themes/stylix.nix
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
