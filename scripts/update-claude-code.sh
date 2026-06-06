#!/usr/bin/env bash
# Update claude-code overlay to the latest version
# Usage: ./scripts/update-claude-code.sh [version]
# If no version is provided, fetches the latest version from npm
#
# Upstream switched from a Node.js cli.js bundle to per-platform native binaries
# distributed via @anthropic-ai/claude-code-{platform}-{arch}. We track the
# linux-x64 binary directly — no package-lock.json or npm deps to manage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_FILE="${SCRIPT_DIR}/../overlays/claude-code.nix"
WRAPPER_PACKAGE="@anthropic-ai/claude-code"
BINARY_PACKAGE="@anthropic-ai/claude-code-linux-x64"

# Get version (from argument or latest release of the wrapper package)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from npm..."
    VERSION=$(curl -s "https://registry.npmjs.org/${WRAPPER_PACKAGE}/latest" | jq -r '.version')
fi

echo "Updating claude-code to v${VERSION}"

# Get current version from overlay
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$OVERLAY_FILE" || echo "unknown")
echo "Current version: ${CURRENT_VERSION}"

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
    echo "Already at version ${VERSION}, nothing to do"
    exit 0
fi

# Fetch source hash for the linux-x64 native binary tarball
echo "Fetching source hash for ${BINARY_PACKAGE}@${VERSION}..."
SRC_HASH=$(nix-prefetch-url --unpack "https://registry.npmjs.org/${BINARY_PACKAGE}/-/claude-code-linux-x64-${VERSION}.tgz" 2>/dev/null)
SRC_HASH_SRI=$(nix hash convert --hash-algo sha256 "$SRC_HASH")
echo "Source hash: ${SRC_HASH_SRI}"

# Update the overlay file
echo "Updating ${OVERLAY_FILE}..."
cat > "$OVERLAY_FILE" << EOF
# Override claude-code to v${VERSION} (native binary release)
# Auto-updated by scripts/update-claude-code.sh
#
# Upstream switched from a Node.js cli.js bundle to a per-platform native binary
# distributed via @anthropic-ai/claude-code-{platform}-{arch}. We pull the
# linux-x64 binary directly and wrap it with the same env vars as the previous
# nixpkgs derivation.
#
# The native binary is a Bun-compiled standalone executable. autoPatchelfHook
# (or any patchelf invocation that grows the file) shifts Bun's embedded-bundle
# trailer offset, causing Bun to fall back to plain runtime mode — \`claude
# --version\` then prints Bun's version and \`--help\` shows Bun's help. To keep
# the binary byte-identical, we invoke it via an explicit ld-linux loader
# instead of patching its interpreter.
final: prev:
let
  version = "${VERSION}";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-\${version}.tgz";
    hash = "${SRC_HASH_SRI}";
  };
  loader = "\${prev.glibc}/lib/ld-linux-x86-64.so.2";
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
      install -Dm755 claude \$out/libexec/claude-code/claude
      makeWrapper \${loader} \$out/bin/claude \\
        --argv0 claude \\
        --add-flags "--library-path \${libPath}" \\
        --add-flags "\$out/libexec/claude-code/claude" \\
        --set DISABLE_AUTOUPDATER 1 \\
        --set-default FORCE_AUTOUPDATE_PLUGINS 1 \\
        --set DISABLE_INSTALLATION_CHECKS 1 \\
        --unset DEV \\
        --prefix PATH : \${
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
EOF

# Remove the now-unused package-lock.json if present
LEGACY_LOCKFILE="${SCRIPT_DIR}/../overlays/claude-code-package-lock.json"
if [[ -f "$LEGACY_LOCKFILE" ]]; then
    rm -f "$LEGACY_LOCKFILE"
    echo "Removed legacy ${LEGACY_LOCKFILE}"
fi

echo "Done! Updated claude-code overlay to v${VERSION}"
echo "Run 'rebuild-system' to apply"
