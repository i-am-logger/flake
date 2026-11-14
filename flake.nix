{
  description = "Personal NixOS + nix-darwin Configuration";

  inputs = {
    # mynixos - Typed functional DSL providing all dependencies.
    # Tracked from GitHub rather than a local path so the same lock resolves on
    # every host (the Linux boxes and the Mac). To iterate on the DSL locally:
    #   nixos-rebuild/darwin-rebuild ... --override-input mynixos ~/Code/mynixos
    mynixos = {
      url = "github:i-am-logger/mynixos";
    };
    # Claude Desktop for Linux (unofficial community port)
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "mynixos/nixpkgs";
    };
    # yoga's amdgpu test kernel - built from the amdgpu-vm-tlb-event-driven branch
    # of the i-am-logger/linux fork instead of per-host .patch files (see
    # systems/yoga; flake=false => tracked files only). On a github fork rather
    # than a local checkout so it resolves on every host, not just where the
    # branch is checked out. Linux-only: the Mac never forces this input.
    yoga-kernel = {
      url = "github:i-am-logger/linux/amdgpu-vm-tlb-event-driven";
      flake = false;
    };
  };

  outputs =
    { self
    , mynixos
    , yoga-kernel
    , ...
    }:
    let
      # Re-export nixpkgs from mynixos for convenience
      inherit (mynixos.inputs) nixpkgs;
      inherit (nixpkgs) lib;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      darwinPkgs = import nixpkgs { system = "aarch64-darwin"; };
    in
    {
      # TODO: move to mynixos
      formatter = {
        x86_64-linux = pkgs.nixpkgs-fmt;
        aarch64-darwin = darwinPkgs.nixpkgs-fmt;
      };

      nixosConfigurations = {
        # HOSTS YOU CAN INSTALL, and only those.
        #
        # The radicle seed and CI builder are machines too, but they are not
        # hosts: they have no disk, so no bootable toplevel, and they are run as
        # containers by whichever host declares them in
        # my.virtualisation.containers -- yoga, today, which builds them in its
        # own file. Listing them here made `nix flake check` try to build a
        # bootable system for a machine with no root filesystem and fail, and
        # forced a `self` reference to thread them back into yoga.
        #
        # Their images are reachable as packages.<system>.role-image-<name>.
        yoga = import ./systems/yoga {
          inherit mynixos yoga-kernel;
          claude-desktop = null; # FIXME: upstream uses removed nodePackages.asar
        };
        ads-dev1 = import ./systems/ads-dev1 { inherit mynixos; };
        skyspy-dev = import ./systems/skyspy-dev { inherit mynixos; };

        # TODO: move to mynixos Installer ISO
        installer-iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./installer ];
          specialArgs = { inherit (mynixos) inputs; };
        };
      };

      # macOS hosts.
      darwinConfigurations = {
        "aether5d-dev" = import ./systems/aether5d-dev { inherit mynixos; };
      };

      # TODO: move to mynixos
      # Packages
      packages.x86_64-linux = {
        # Installer ISO package
        installer-iso = self.nixosConfigurations.installer-iso.config.system.build.isoImage;
      }
      // (
        # The container roles, as images. They are not nixosConfigurations (see
        # the comment there), so this is what keeps `nix build` able to reach
        # one -- which is how a role is inspected without running it. Derived
        # from what yoga actually declares, so a role cannot be exposed here
        # and not run, or run and not exposed.
        let
          roles = self.nixosConfigurations.yoga.config.my.virtualisation.containers;
        in
        lib.listToAttrs (
          map
            (role: {
              name = "role-image-${role.name}";
              value = role.system.config.system.build.image;
            })
            roles
        )
      );
    };
}
