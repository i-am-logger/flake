{ lib, pkgs, ... }:

let
  # Stable version details
  warp-latest-version = "0.2025.04.02.08.11.stable_03";
  warp-latest-hash = "sha256-wHiiKgTqAC30VMH0VhslmaNZyCwYEs6N915jlkxL8d8=";

  # Create a properly configured warp-terminal derivation
  warp-terminal-stable = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "warp-terminal";
    version = warp-latest-version;

    src = pkgs.fetchurl {
      url = "https://releases.warp.dev/stable/v${warp-latest-version}/warp-terminal-v${warp-latest-version}-1-${if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64"}.pkg.tar.zst";
      hash = warp-latest-hash;
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      zstd
      makeWrapper
    ];

    buildInputs = with pkgs; [
      alsa-lib
      brotli
      bzip2
      curl
      expat
      fontconfig
      freetype
      glibc
      keyutils
      krb5
      libglvnd
      libpng
      libpsl
      libssh2
      libunistring
      libxkbcommon
      nghttp2
      openssl
      vulkan-loader
      wayland
      wayland-protocols
      libdrm
      mesa
      xdg-utils
      xorg.libX11
      xorg.libxcb
      xorg.libXcursor
      xorg.libXi
      zlib
      (lib.getLib stdenv.cc.cc) # libstdc++.so and libgcc_s.so
    ];

    runtimeDependencies = with pkgs; [
      libglvnd
      libxkbcommon
      vulkan-loader
      wayland
      wayland-protocols
      libdrm
      mesa
      pipewire
      xdg-desktop-portal-wlr
      xdg-utils
      xorg.libX11
      xorg.libxcb
      xorg.libXcursor
      xorg.libXi
    ];

    sourceRoot = ".";

    dontBuild = true;
    dontConfigure = true;

    unpackPhase = ''
      runHook preUnpack
      tar xf $src
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/opt
      cp -r opt/warpdotdev $out/opt/
      cp -r usr/bin/warp-terminal $out/bin/
      if [ -d usr/share ]; then
        cp -r usr/share $out/share
      fi

      # Patch the executable to point to the correct location
      substituteInPlace $out/bin/warp-terminal \
        --replace "/opt/warpdotdev" "$out/opt/warpdotdev"
      # Wrap the binary with required environment
      wrapProgram $out/bin/warp-terminal \
        --set WARP_ENABLE_WAYLAND 1 \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.runtimeDependencies}"
    '';

    meta = {
      description = "Rust-based terminal (Stable version)";
      homepage = "https://www.warp.dev";
      license = lib.licenses.unfree;
      maintainers = with lib.maintainers; [ ];
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  });
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or pkg.name) [
      "warp-terminal"
    ];

  environment.systemPackages = [
    warp-terminal-stable
  ];

  environment.sessionVariables = {
    WARP_ENABLE_WAYLAND = lib.mkForce 1;
  };

  # Configure persistence for warp-terminal
  # environment.persistence."/persist" = {
  #   users.logger = {
  #     directories = [
  #       ".config/warp-terminal"
  #       ".local/state/warp-terminal"
  #     ];
  #   };
  # };
}
