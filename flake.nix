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
    # yoga's amdgpu test kernel - built from a local git branch instead of
    # per-host .patch files (see systems/yoga; flake=false => tracked files only).
    # Linux-only: the Mac never forces this input.
    yoga-kernel = {
      url = "git+file:///home/logger/Code/github/logger/linux?ref=amdgpu-vm-tlb-event-driven";
      flake = false;
    };
    # Local OpenRGB checkout, for building/testing OpenRGB changes (CLI apply
    # latency, Keychron K2 HE native-vs-QMK RGB driver) from a local branch
    # instead of the pinned nixpkgs release. flake=false => tracked files only;
    # tracks the `perf/cli-latency` branch. Iterate: commit on that branch, then
    # `nix flake update openrgb-src`, then rebuild.
    openrgb-src = {
      url = "git+file:///home/logger/Code/github/logger/openrgb?ref=perf/cli-latency";
      flake = false;
    };
  };

  outputs =
    { self
    , mynixos
    , secrets
    , yoga-kernel
    , openrgb-src
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
        yoga = import ./systems/yoga {
          inherit mynixos secrets yoga-kernel openrgb-src;
          claude-desktop = null; # FIXME: upstream uses removed nodePackages.asar
        };
        skyspy-dev = import ./systems/skyspy-dev { inherit mynixos secrets; };

        # TODO: move to mynixos Installer ISO
        installer-iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./installer ];
          specialArgs = { inherit (mynixos) inputs; };
        };
      };

      # macOS hosts. Note `secrets` is deliberately not threaded in here — that
      # input points at a Linux-only path and is never forced by this config.
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
