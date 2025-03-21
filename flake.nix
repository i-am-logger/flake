{
  description = "My Personal NixOS ricing";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "/home/snick/Code/snick/nix/nixpkgs";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05"; #-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # managing secrets
    sops-nix.url = "github:Mic92/sops-nix";

    secrets = {
      url = "/home/snick/.secrets/";
      flake = false;
    };

    # managing partitions
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    inputs@{
      self,
      nixos-hardware,
      nixpkgs,
      disko,
      flake-utils,
      sops-nix,
      secrets,
      home-manager,
      stylix,
      ...
    }:
    let
      username = "snick";
      lib = nixpkgs.lib;
      # packages-overlay = import ./packages/overlay.nix;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true; # Allow proprietary software

        # overlays = [ packages-overlay ];
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
        handlink = lib.nixosSystem {
          specialArgs = {
            inherit
              secrets
              disko
              self
              inputs
              username
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
              #home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.users.${username} = {
                imports = [
                  # nix-doom-emacs.hmModule
                  ./home/${username}.nix
                ];
              };
            }

            # Theme
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
