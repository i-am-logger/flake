{
  description = "My Personal NixOS ricing";

  inputs = {
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
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags.url = "github:Aylur/ags";
    # themes
    stylix.url = "github:danth/stylix";
    # stylix.url = "github:realsnick/stylix";
    # stylix.url = "../../../home/snick/Code/snick/stylix";

    # NixOS hardware configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Secure Boot with lanzaboote
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixos-hardware,
      nixpkgs,
      disko,
      impermanence,
      flake-utils,
      sops-nix,
      secrets,
      home-manager,
      stylix,
      lanzaboote,
      ags,
      ...
    }:
    let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true; # Allow proprietary software
        # nixpkgs.config.permittedInsecurePackages = [
        #   "nix-2.15.3"
        #   "nix-2.19.3"
        #   "nix-2.16.2"
        #   "nix"
        # ];
      };

    in
    {
      nixosConfigurations = {
        yoga = lib.nixosSystem {
          specialArgs = {
            inherit
              secrets
              disko
              impermanence
              self
              inputs
              stylix
              ;
          };
          modules = [
            ./Systems/yoga/configuration.nix
            disko.nixosModules.disko
            {
              disko.devices = import ./Systems/yoga/disko.nix {
                lib = nixpkgs.lib;
              };
            }
            ./hosts/yoga.nix
            modules/motd
            home-manager.nixosModules.home-manager
            {
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.users.logger = {
                imports = [
                  ./home/logger.nix
                ];
              };
            }
            # Theme
            stylix.nixosModules.stylix
            ./Themes/stylix.nix
          ];
        };
        handlink = lib.nixosSystem {
          specialArgs = {
            inherit
              pkgs
              secrets
              disko
              self
              inputs
              ;
          };
          modules = [
            # hardware
            nixos-hardware.nixosModules.lenovo-legion-16irx8h # 2023
            # partitioning
            (
              { modulesPath, ... }:
              {
                imports = [
                  (modulesPath + "/installer/scan/not-detected.nix")
                  (modulesPath + "/profiles/qemu-guest.nix")
                  disko.nixosModules.disko
                ];
                disko.devices = import ./Systems/mirage/configuration-disks.nix {
                  lib = nixpkgs.lib;
                };
              }
            )
            # {
            #   nixpkgs.config.permittedInsecurePackages = [
            #     "nix-2.19.3"
            #     "nix-2.15.3"
            #     "nix-2.16.2"
            #     "nix"
            #   ];
            # }
            # secrets
            sops-nix.nixosModules.sops
            # system
            ./hosts/handlink.nix
            modules/motd

            # nix-ros-overlay.nixosModules.default
            # Home
            home-manager.nixosModules.home-manager
            {
              # home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.users.snick = {
                imports = [
                  ./home/snick.nix
                ];
              };
            }

            # Theme
            stylix.nixosModules.stylix
            Themes/stylix.nix
          ];
        };
      };
    };
}
