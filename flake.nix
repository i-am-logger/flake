{
  description = "My Personal NixOS ricing";

  inputs = {
    nixos-hardware.url = "github:realsnick/nixos-hardware/master";
    #nixos-hardware.url = "../../../home/snick/Code/nix/nixos-hardware";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05"; #-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    disko = {
      url = github:nix-community/disko;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      flake = false;
    };

    hypr-picker.url = "github:hyprwm/hyprpicker";
    hypr-contrib.url = "github:hyprwm/contrib";

    stylix.url = "github:danth/stylix";
    #stylix.url = "github:realsnick/stylix";
    #stylix.url = "../../../home/snick/Code/github/snick/stylix";
  };

  outputs = inputs @ {
    self,
    nixos-hardware,
    nixpkgs,
    nixpkgs-stable,
    disko,
    flake-utils,
    home-manager,
    hyprland,
    hypr-picker,
    hypr-contrib,
    stylix,
    ...
  }: let
    username = "snick";
    lib = nixpkgs.lib;
    pkgs-stable = import nixpkgs-stable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true; # Allow proprietary software
      overlays = [
        (final: prev: {
          xdg-desktop-portal-hyprland = inputs.xdph.packages.${prev.system}.default.override {
            hyprland-share-picker = inputs.nixos-hardware.packages.${prev.system}.hyprland-share-picker.override {inherit hyprland;};
          };
        })
      ];
    };
  in {
    overlays.default = _: prev: rec {
      xdg-desktop-portal-hyprland = inputs.xdph.packages.${prev.system}.default.override {
        hyprland-share-picker = inputs.xdph.packages.${prev.system}.hyprland-share-picker.override {inherit hyprland;};
      };
    };

    nixosConfigurations = {
      handlink = lib.nixosSystem {
        specialArgs = {inherit pkgs pkgs-stable disko self inputs hyprland username;};
        modules = [
          ({modulesPath, ...}: {
            imports = [
              (modulesPath + "/installer/scan/not-detected.nix")
              (modulesPath + "/profiles/qemu-guest.nix")
              # (./Systems/mirage/boot.nix)
              disko.nixosModules.disko
            ];

            disko.devices = import ./Systems/mirage/configuration-disks.nix {
              lib = nixpkgs.lib;
            };
          })
          # hardware
          nixos-hardware.nixosModules.lenovo-legion-16irx8h #2023

          # system
          modules/oct-motd
          hyprland.nixosModules.default
          {programs.hyprland.enable = true;}

          # host
          ./hosts/handlink.nix
          home-manager.nixosModules.home-manager
          {
            #home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${username} = {
              imports = [
                hyprland.homeManagerModules.default
                {wayland.windowManager.hyprland.enable = true;}
                ./home/${username}.nix
              ];
            };
          }

          # system
          Themes/stylix.nix
          stylix.nixosModules.stylix
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
