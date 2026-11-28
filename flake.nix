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
    # One nixpkgs for everything here: mynixos's. A follows adds no lock node,
    # so the lock keeps a single nixpkgs (baud's own pins aside).
    nixpkgs.follows = "mynixos/nixpkgs";
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
    , nixpkgs
    , yoga-kernel
    , ...
    }:
    let
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
        # my.virtualisation.containers.guests -- yoga, today, which builds them in its
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
        # The account balancer as ads-dev1 installs it: ads-dev1's pkgs carry
        # the herdr overlay, so this is the same derivation.
        account-balance = self.nixosConfigurations.ads-dev1.pkgs.callPackage ./pkgs/account-balance { };
      }
      // (
        # The container roles, as images. They are not nixosConfigurations (see
        # the comment there), so this is what keeps `nix build` able to reach
        # one -- which is how a role is inspected without running it. Derived
        # from what yoga actually declares, so a role cannot be exposed here
        # and not run, or run and not exposed.
        let
          roles = self.nixosConfigurations.yoga.config.my.virtualisation.containers.guests;
        in
        lib.listToAttrs (
          map
            (role: {
              name = "role-image-${role.name}";
              # A system guest builds its image; an image guest IS one.
              value = if role.system != null then role.system.config.system.build.image else role.image;
            })
            roles
        )
      );

      checks.x86_64-linux = {
        # account-balance against a stub herdr and fixture usage files: keying
        # by <session>/<pane>, --session on every call, held sessions, pools,
        # stale usage and the lock (pkgs/account-balance/test/check.sh).
        account-balance = pkgs.callPackage ./pkgs/account-balance/check.nix { };

        # account-balance keeps moves.log and the rest in
        # ~/.local/state/account-balance, and /home is tmpfs: one of logger's
        # persisted directories on ads-dev1 must cover it, or the log vanishes
        # on reboot. Fails at evaluation, naming the path.
        account-balance-persisted =
          let
            target = ".local/state/account-balance";
            dirs = lib.concatMap
              (p: map (d: d.directory) (p.users.logger.directories or [ ]))
              (lib.attrValues self.nixosConfigurations.ads-dev1.config.environment.persistence);
            covers = d: d == target || lib.hasPrefix "${lib.removeSuffix "/" d}/" target;
          in
          assert lib.assertMsg (lib.any covers dirs)
            "ads-dev1 persists no directory of logger's covering ~/${target}";
          pkgs.runCommand "account-balance-persisted" { } ''
            echo "PASS  persisted: ~/${target} is under a persisted directory of logger on ads-dev1" | tee "$out"
          '';

        # mynixos's status-line recorder and the balancer agree on
        # usage-latest.json: the real statusLine command from ads-dev1's merged
        # Claude settings writes a reading that `account-balance usage` reads as
        # a numeric 5-hour % of age 0.
        account-balance-statusline = pkgs.callPackage ./pkgs/account-balance/statusline-check.nix {
          balancer = self.packages.x86_64-linux.account-balance;
          hmConfig = self.nixosConfigurations.ads-dev1.config.home-manager.users.logger;
        };
      };
    };
}
