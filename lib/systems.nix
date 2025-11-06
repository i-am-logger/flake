{ inputs, lib, nixpkgs, ... }:

{
  mkSystem = {
    hostname,
    hardware ? [],  # List of hardware modules
    machine ? null,  # Deprecated: use hardware instead
    users ? [],
    stacks ? {},
    config ? null,
    extraModules ? [],
  }:
    lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (inputs) secrets disko impermanence stylix lanzaboote self;
      };
      
      modules = (builtins.trace "Hardware modules: ${builtins.toString hardware}" hardware) ++ [
      ]
      ++ (lib.optionals (machine != null) [
        # Machine hardware (deprecated approach)
        machine.path
      ])
      ++ (lib.optionals (machine != null && machine.disko != null) [
        # Disko partitioning (if machine uses it)
        inputs.disko.nixosModules.disko
        {
          disko.devices = import machine.disko { lib = nixpkgs.lib; };
        }
      ])
      ++ (lib.optionals (machine != null && machine.nixos-hardware != null) [
        # NixOS hardware module (if specified)
        inputs.nixos-hardware.nixosModules.${machine.nixos-hardware}
      ])
      ++ (lib.optionals (config != null) [
        # System-specific configuration
        config
      ])
      ++ [
        
        # Set hostname
        { networking.hostName = hostname; }
        
        # NixOS users
        {
          imports = map (user: user.nixosUser) users;
        }
        
        # Home Manager for users
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users = lib.genAttrs 
            (map (user: user.name) users)
            (name: 
              let user = lib.findFirst (u: u.name == name) null users;
              in { imports = [ user.homeManager ]; }
            );
        }
        
        # Infrastructure and Stacks
        ../Systems/Infra
        ../Systems/Stacks
        { inherit stacks; }
        
        # Theme
        inputs.stylix.nixosModules.stylix
        ../Themes/stylix.nix
        
        # Common modules
        ../modules/motd
      ] ++ extraModules;
    };
}
