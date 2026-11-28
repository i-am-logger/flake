{
  description = "Personal NixOS + nix-darwin Configuration";

  inputs = {
    # mynixos - Typed functional DSL providing all dependencies.
    # Tracked from GitHub rather than a local path so the same lock resolves on
    # every host (the Linux boxes and the Mac). To iterate on the DSL locally:
    #   nixos-rebuild/darwin-rebuild ... --override-input mynixos ~/Code/mynixos
    mynixos = {
      url = "github:i-am-logger/mynixos";
      # vogix comes from flake's own input below (owner, 2026-11-28).
      inputs.vogix.follows = "vogix";
    };
    # vogix, ahead of mynixos's pin: the owner brings vogix v1 onto the hosts
    # through this input (2026-11-28), with no mynixos edits. Pinned by commit
    # on origin master until cops tags vogix; mynixos's own vogix input follows
    # it, and vogix's inputs follow mynixos's as mynixos sets them, so the lock
    # keeps one nixpkgs and one home-manager.
    vogix = {
      url = "github:i-am-logger/vogix/9fe5be6a2d320cea50fafc68248d9556945aa57a";
      inputs = {
        nixpkgs.follows = "mynixos/nixpkgs";
        home-manager.follows = "mynixos/home-manager";
        rust-overlay.follows = "mynixos/lanzaboote/rust-overlay";
        devenv.inputs.git-hooks.follows = "mynixos/git-hooks";
      };
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
      # The flake's own checks, each a function of its data (checks/*.nix).
      check = lib.genAttrs [ "persisted-covers" "claude-accounts" "vogix-v1-host" "fail-in-build" "trusted-users" ]
        (n: pkgs.callPackage (./checks + "/${n}.nix") { });
      # A host's persisted directories for logger, as paths under ~.
      persistedDirs = c: lib.concatMap
        (p: map (d: d.directory) (p.users.logger.directories or [ ]))
        (lib.attrValues c.environment.persistence);
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

      # VM tests (KVM), built on demand, never by `nix flake check`.
      tests.x86_64-linux = lib.genAttrs' [ true false ] (v: lib.nameValuePair
        "claude-projects-binds-${if v then "fixed" else "unfixed"}"
        (import ./checks/claude-projects-binds-vm.nix { inherit pkgs; withFix = v; }));

      checks.x86_64-linux = {
        # account-balance against a stub herdr and fixture usage files: keying
        # by <session>/<pane>, --session on every call, held sessions, pools,
        # stale usage and the lock (pkgs/account-balance/test/check.sh).
        account-balance = pkgs.callPackage ./pkgs/account-balance/check.nix { };

        # account-balance keeps moves.log and the rest in
        # ~/.local/state/account-balance, and /home is tmpfs: one of logger's
        # persisted directories on ads-dev1 must cover it, or the log vanishes
        # on reboot.
        account-balance-persisted = check.persisted-covers {
          name = "account-balance-persisted";
          host = "ads-dev1";
          target = ".local/state/account-balance";
          dirs = persistedDirs self.nixosConfigurations.ads-dev1.config;
        };

        # mynixos's status-line recorder and the balancer agree on
        # usage-latest.json: the real statusLine command from ads-dev1's merged
        # Claude settings writes a reading that `account-balance usage` reads as
        # a numeric 5-hour % of age 0.
        account-balance-statusline = pkgs.callPackage ./pkgs/account-balance/statusline-check.nix {
          balancer = self.packages.x86_64-linux.account-balance;
          hmConfig = self.nixosConfigurations.ads-dev1.config.home-manager.users.logger;
        };

        # CLAUDE.md is exactly its byte budget in budgets.toml (at most 4096):
        # a pointer to the Nix rules plus flake's deltas (decision 0180).
        instructions-size = import ./checks/instructions-size.nix
          { inherit (pkgs) runCommand; }
          { claudeMd = ./CLAUDE.md; budgets = ./budgets.toml; };

        # ads-dev1's Claude accounts: each persisted as ~/.claude-<name>, and
        # mynixos's own claudeAccounts step, run in a scratch home, links its
        # four shared entries to ~/.claude. The expected list is written here,
        # apart from the host's, so a dropped or missing account fails.
        claude-accounts = check.claude-accounts {
          expected = [ "cdev1" "cdev2" "cdev3" "cdev5" "cdev6" "cdev7" ]
            ++ map (n: "aether5d-cdev${toString n}") (lib.range 1 10);
          dirs = persistedDirs self.nixosConfigurations.ads-dev1.config;
          step = self.nixosConfigurations.ads-dev1.config.home-manager.users.logger.home.activation.claudeAccounts.data or "";
        };

        # vogix reaches the hosts through flake's own `vogix` input: mynixos's
        # vogix input follows it (owner, 2026-11-28: vogix v1 comes onto the host
        # by this override, with no mynixos edits). Checks the lock's follows,
        # that both names resolve to one source, and that ads-dev1 and yoga
        # enable vogix and evaluate with it.
        vogix-v1-host = check.vogix-v1-host {
          own = self.inputs.vogix or null;
          follows = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.mynixos.inputs.vogix or null;
          mynixosVogix = mynixos.inputs.vogix.outPath or null;
          hosts = lib.genAttrs [ "ads-dev1" "yoga" ] (h: {
            vogix = self.nixosConfigurations.${h}.config.home-manager.users.logger.programs.vogix.enable;
            drvPath = self.nixosConfigurations.${h}.config.system.build.toplevel.drvPath;
          });
        };

      }
      # Each NixOS host's Nix trusts root only (security finding S2a, extended
      # to every host by the owner's yes via lead-myoslabs, 2026-11-28).
      // lib.genAttrs' [ "yoga" "ads-dev1" "skyspy-dev" ] (h: lib.nameValuePair "trusted-users-${h}"
        (check.trusted-users { host = h; trusted = self.nixosConfigurations.${h}.config.nix.settings.trusted-users; }))
      // {

        # Every check above fails in its own build, never at evaluation, which
        # would stop `nix flake check` before the rest report. Each case gives a
        # check data that must fail it (checks/fail-in-build.nix).
        checks-fail-in-build = check.fail-in-build {
          account-balance-persisted = check.persisted-covers {
            name = "account-balance-persisted";
            host = "fixture";
            target = ".local/state/account-balance";
            dirs = [ ".cache" ];
          };
          claude-accounts = check.claude-accounts {
            expected = [ "fixture" ];
            dirs = [ ];
            step = "";
          };
          vogix-v1-host = check.vogix-v1-host {
            own = null;
            follows = "vogix";
            mynixosVogix = null;
            hosts = { };
          };
          trusted-users = check.trusted-users { host = "fixture"; trusted = [ "root" "@wheel" ]; };
          account-balance-statusline = pkgs.callPackage ./pkgs/account-balance/statusline-check.nix {
            balancer = self.packages.x86_64-linux.account-balance;
            hmConfig = { home.activation = { }; home.activationPackage = null; };
          };
        };
      };
    };
}
