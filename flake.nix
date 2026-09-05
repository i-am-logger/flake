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
    # Local OpenRGB checkout, for building/testing OpenRGB changes (CLI apply
    # latency, Keychron K2 HE native-vs-QMK RGB driver) from a local branch
    # instead of the pinned nixpkgs release. flake=false => tracked files only;
    # tracks the `perf/cli-latency` branch. Iterate: commit on that branch, then
    # `nix flake update openrgb-src`, then rebuild.
    openrgb-src = {
      url = "github:CalcProgrammer1/OpenRGB";
      flake = false;
    };
  };

  outputs =
    {
      self,
      mynixos,
      yoga-kernel,
      openrgb-src,
      ...
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
        # The fleet's machines, each declared once. A radicle seed is a machine
        # like yoga is a machine: it has a hostname, it enables some services,
        # and nothing about it says how it will be run. yoga decides that below
        # by putting them in `my.virtualisation.containers`; either could as
        # easily be a VM, or installed on metal.
        #
        # `host = "yoga"` is what puts yoga's name in theirs, because a tailnet
        # name must be unique fleet-wide. It is the ONLY literal: the guests
        # derive `radicle-yoga-{seed,x64-builder}` from it, the containers take
        # their names from the guests, and the host-side accounts from those.
        radicle-yoga-seed = import ./systems/radicle-seed {
          inherit mynixos;
          host = "yoga";
          # Minted 2026-09-02. NOT disposable: every workstation pins this NID
          # in a `connect` entry, so rotating it means visiting each of them.
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyY9GfELIEcnfz8bAlbPWp68FYgNGADDEPk9J29+3h5";
          identityDir = "/var/lib/radicle-seed-identity";
          # CI runs on the builder and the reports exist only there.
          ciReportsFrom = "http://radicle-yoga-x64-builder.tail46cce1.ts.net:8782/";
          avatarDefault = ./users/logger/avatar.png;
          avatarsByEmail."i-am-logger@users.noreply.github.com" = ./users/logger/avatar.png;
        };

        radicle-yoga-x64-builder = import ./systems/radicle-builder {
          inherit mynixos;
          host = "yoga";
          # Minted 2026-09-01. Disposable by design -- a CI recipe can read it,
          # which is the accepted risk that makes a builder its own machine.
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+Z/2uDBYlhSj6dsI4s7KqOcs0/HBxZX8rIBe/ROzDK";
          identityDir = "/var/lib/radicle-identity";
          connect = [
            "z6Mks9Ty1pdeM6LWsivN674EL3s3qCf8aVo8hw9KN3gmSPwW@radicle-yoga-seed.tail46cce1.ts.net:8776"
          ];
          reportsPublicUrl = "https://radicle-yoga-seed.tail46cce1.ts.net/ci";
        };

        yoga = import ./systems/yoga {
          inherit mynixos yoga-kernel openrgb-src;
          claude-desktop = null; # FIXME: upstream uses removed nodePackages.asar
          radicleGuests = [
            self.nixosConfigurations.radicle-yoga-seed
            self.nixosConfigurations.radicle-yoga-x64-builder
          ];
        };
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
      };
    };
}
