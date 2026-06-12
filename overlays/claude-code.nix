# Override claude-code to v2.1.170 (native binary release)
# Auto-updated by scripts/update-claude-code.sh
#
# Upstream switched from a Node.js cli.js bundle to a per-platform native binary
# distributed via @anthropic-ai/claude-code-{platform}-{arch}. We pull the
# linux-x64 binary directly and wrap it with the same env vars as the previous
# nixpkgs derivation.
#
# The native binary is a Bun-compiled standalone executable. autoPatchelfHook
# (or any patchelf invocation that grows the file) shifts Bun's embedded-bundle
# trailer offset, causing Bun to fall back to plain runtime mode — `claude
# --version` then prints Bun's version and `--help` shows Bun's help. To keep
# the binary byte-identical, we invoke it via an explicit ld-linux loader
# instead of patching its interpreter.
final: prev:
let
  version = "2.1.170";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${version}.tgz";
    hash = "sha256-boRtO4oV/PP30bB0wWKYyuR2woZV3joAvqyxpiL6txs=";
  };
  loader = "${prev.glibc}/lib/ld-linux-x86-64.so.2";
  libPath = prev.lib.makeLibraryPath [ prev.stdenv.cc.cc.lib ];
in
{
  claude-code = prev.stdenvNoCC.mkDerivation {
    pname = "claude-code";
    inherit version src;

    nativeBuildInputs = [ prev.makeWrapper ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 claude $out/libexec/claude-code/claude
      makeWrapper ${loader} $out/bin/claude \
        --argv0 claude \
        --add-flags "--library-path ${libPath}" \
        --add-flags "$out/libexec/claude-code/claude" \
        --set DISABLE_AUTOUPDATER 1 \
        --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --unset DEV \
        --prefix PATH : ${
          prev.lib.makeBinPath [
            prev.procps
            prev.bubblewrap
            prev.socat
          ]
        }
      runHook postInstall
    '';

    meta = {
      description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
      homepage = "https://github.com/anthropics/claude-code";
      downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
      license = prev.lib.licenses.unfree;
      mainProgram = "claude";
      sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };
}
