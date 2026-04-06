{
  description = "Personal NixOS Configuration";

  inputs = {
    # mynixos - Typed functional DSL providing all dependencies
    mynixos.url = "path:/home/logger/Code/github/logger/mynixos";
    # Personal secrets (not managed by mynixos)
    secrets = {
      url = "/home/logger/.secrets/";
      flake = false;
    };
    # Claude Desktop for Linux (unofficial community port)
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "mynixos/nixpkgs";
    };
  };

  outputs =
    { self
    , mynixos
    , secrets
    , claude-desktop
    , ...
    }:
    let
      # Re-export nixpkgs from mynixos for convenience
      nixpkgs = mynixos.inputs.nixpkgs;
      lib = nixpkgs.lib;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      # TODO: move to mynixos
      formatter.x86_64-linux = pkgs.nixpkgs-fmt;

      nixosConfigurations = {
        yoga = import ./systems/yoga { inherit mynixos secrets; claude-desktop = null; # FIXME: upstream uses removed nodePackages.asar
        };
        skyspy-dev = import ./systems/skyspy-dev { inherit mynixos secrets; };

        # TODO: move to mynixos Installer ISO
        installer-iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./installer ];
          specialArgs = { inherit (mynixos) inputs; };
        };
      };

      # TODO: move to mynixos
      # Packages
      packages.x86_64-linux = {
        # Installer ISO package
        installer-iso = self.nixosConfigurations.installer-iso.config.system.build.isoImage;
      };
    };
}
