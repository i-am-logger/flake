{ lib, pkgs, ... }:

let
  # Import the original warp-terminal derivation
  warp-terminal-base = pkgs.warp-terminal;

  # Preview version details
  warp-preview-version = "0.2025.04.02.08.11.preview_02";
  warp-preview-hash = "sha256-0zwWsoIGtvWha2cXu5okT2LrEf80ooHdQa4qhMMkyEA=";

  # Create a modified copy of the warp-terminal derivation for the preview version
  warp-terminal-preview = pkgs.callPackage (
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
      xdg-utils,
      xorg,
      zlib,
      makeWrapper,
      waylandSupport ? false,
    }:

    let
      pname = "warp-terminal-preview";
      version = warp-preview-version;

      # Determine architecture
      linux_arch = if stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64";

      linux = stdenv.mkDerivation (finalAttrs: {
        inherit pname version;
        src = fetchurl {
          url = "https://releases.warp.dev/preview/v${version}/warp-terminal-preview-v${version}-1-${linux_arch}.pkg.tar.zst";
          hash = warp-preview-hash;
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

        buildInputs = [
          alsa-lib # libasound.so.2
          curl
          fontconfig
          (lib.getLib stdenv.cc.cc) # libstdc++.so libgcc_s.so
          zlib
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
        ] ++ lib.optionals waylandSupport [ wayland ];

        installPhase =
          ''
            runHook preInstall

            mkdir $out
            cp -r opt usr/* $out

          ''
          + lib.optionalString waylandSupport ''
            wrapProgram $out/bin/warp-terminal-preview --set WARP_ENABLE_WAYLAND 1
          ''
          + ''
            runHook postInstall
          '';

        # Use the same meta information as the original package
        meta = (warp-terminal-base.meta or { }) // {
          description = "Rust-based terminal (Preview version)";
          license = lib.licenses.unfree;
        };
      });

    in
    linux
  ) { };
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
  ];

  environment.sessionVariables = {
    WARP_ENABLE_WAYLAND = 0;
  };

  # Configure persistence for warp-terminal-preview
  # environment.persistence."/persist" = {
  #   users.logger = {
  #     directories = [
  #       ".config/warp-terminal-preview"
  #       ".local/state/warp-terminal-preview"
  #     ];
  #   };
  # };
}
