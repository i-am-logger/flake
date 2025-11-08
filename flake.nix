{
  description = "My Personal NixOS ricing";

  inputs = {
    # nixpkgs.url = "github:i-am-logger/nixpkgs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "/home/snick/Code/snick/nix/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    # managing secrets
    sops-nix.url = "github:Mic92/sops-nix";

    secrets = {
      url = "/home/logger/.secrets/";
      flake = false;
    };

    # managing partitions
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    # managing /home - user configurations - dotfiles
    home-manager = {
      url = "github:i-am-logger/home-manager?ref=feature/webapps-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags.url = "github:Aylur/ags";
    ironbar.url = "github:JakeStanger/ironbar";
    # themes
    stylix.url = "github:danth/stylix";
    # stylix.url = "github:realsnick/stylix";
    # stylix.url = "../../../home/snick/Code/snick/stylix";

    # NixOS hardware configurations
    # Using local fork for Legion-specific fixes
    # nixos-hardware.url = "/home/logger/GitHub/logger/nixos-hardware";
    nixos-hardware.url = "github:i-am-logger/nixos-hardware";
    # nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Secure Boot with lanzaboote
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
    };
  };

  outputs =
    inputs@{ self
    , nixos-hardware
    , nixpkgs
    , disko
    , impermanence
    , flake-utils
    , sops-nix
    , secrets
    , home-manager
    , stylix
    , lanzaboote
    , ags
    , ironbar
    , ...
    }:
    let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        # config.allowUnfree = true; # Allow proprietary software
        # nixpkgs.config.permittedInsecurePackages = [
        #   "nix-2.15.3"
        #   "nix-2.19.3"
        #   "nix-2.16.2"
        #   "nix"
        # ];
      };

      myLib = import ./lib { inherit inputs lib nixpkgs; };
    in
    {
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;

      nixosConfigurations = {
        yoga = import ./Systems/yoga { inherit myLib; };
        skyspy-dev = import ./Systems/skyspy-dev { inherit myLib; };
      };
    };
}
