{ lib, pkgs, ... }:

let
  inherit (lib) trace;
  # Import the original warp-terminal derivation
  warp-terminal-base = pkgs.warp-terminal;

  # Preview version details
  #
  warp_preview_version = "0.2025.11.06.20.04.preview_01";
  warp_preview_hash = "sha256-FvNExniCGC87M22oZicc+gkF66swEWb6ROxDrW4pUus=";
  warp-terminal-preview-fn =
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
      zstd,
      alsa-lib,
      curl,
      fontconfig,
      libglvnd,
      libxkbcommon,
      vulkan-loader,
      wayland,
      waylandProtocols,
      libdrm,
      mesa,
      pipewire,
      xdgDesktopPortalWlr,
      xdg-utils,
      xorg,
      zlib,
      makeWrapper,
      waylandSupport ? true,
    }:

    let
      pname = "warp-terminal-preview";
      version = warp_preview_version;

      # Determine architecture
      linux_arch = if stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64";
    in
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version;

      src = fetchurl {
        url = "https://releases.warp.dev/preview/v${version}/warp-terminal-preview-v${version}-1-${linux_arch}.pkg.tar.zst";
        hash = warp_preview_hash;
      };

      sourceRoot = ".";

      postPatch = ''
        substituteInPlace usr/bin/warp-terminal-preview \
          --replace-fail /opt/ $out/opt/
      '';

      nativeBuildInputs = [
        autoPatchelfHook
        zstd
        makeWrapper
      ];

      # Add a debug message to the build
      preBuild = ''
        echo "Building warp-terminal-preview with Wayland support"
        echo "Using waylandProtocols from arguments"
      '';

      buildInputs = [
        alsa-lib # libasound.so.2
        curl
        fontconfig
        (lib.getLib stdenv.cc.cc) # libstdc++.so libgcc_s.so
        zlib
        # Wayland dependencies
        wayland
        waylandProtocols
        libdrm
        mesa
      ];

      runtimeDependencies = [
        libglvnd # for libegl
        libxkbcommon
        stdenv.cc.libc
        vulkan-loader
        xdg-utils
        xorg.libX11
        xorg.libxcb
        xorg.libXcursor
        xorg.libXi
        # Wayland dependencies
        wayland
        waylandProtocols
        libdrm
        mesa
        pipewire
        xdgDesktopPortalWlr
      ];

      installPhase = ''
        runHook preInstall

        mkdir $out
        cp -r opt usr/* $out

        ${lib.optionalString waylandSupport ''
          wrapProgram $out/bin/warp-terminal-preview \
            --set WARP_ENABLE_WAYLAND 1 \
            --set WGPU_BACKEND gl
        ''}

        runHook postInstall
      '';

      # Use the same meta information as the original package
      meta = (warp-terminal-base.meta or { }) // {
        description = "Rust-based terminal (Preview version)";
        license = lib.licenses.unfree;
      };
    });

  # Create a modified copy of the warp-terminal derivation for the preview version
  warp-terminal-preview = trace "Calling warp-terminal-preview with Wayland support" (
    pkgs.callPackage warp-terminal-preview-fn {
      waylandSupport = true;
      # Provide explicit overrides for key dependencies
      waylandProtocols = pkgs.wayland-protocols;
      libdrm = pkgs.libdrm;
      mesa = pkgs.mesa;
      pipewire = pkgs.pipewire;
      xdgDesktopPortalWlr = pkgs.xdg-desktop-portal-wlr;
      xdg-utils = pkgs.xdg-utils;
    }
  );
in
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or pkg.name) [
      # "warp-terminal"
      "warp-terminal-preview"
    ];

  environment.systemPackages = [
    warp-terminal-preview
    pkgs.gh # GitHub CLI for auth token
    pkgs.docker # Required for the Docker-based MCP server
  ];

  # environment.sessionVariables = {
  # WARP_ENABLE_WAYLAND = lib.mkForce 1;
  # WGPU_BACKEND = "gl";
  # };
}
