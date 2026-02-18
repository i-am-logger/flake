#!/usr/bin/env bash
# Update claude-code overlay to the latest version
# Usage: ./scripts/update-claude-code.sh [version]
# If no version is provided, fetches the latest version from npm

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERLAY_FILE="${SCRIPT_DIR}/../overlays/claude-code.nix"
LOCKFILE="${SCRIPT_DIR}/../overlays/claude-code-package-lock.json"
NPM_PACKAGE="@anthropic-ai/claude-code"

# Get version (from argument or latest release)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from npm..."
    VERSION=$(curl -s "https://registry.npmjs.org/${NPM_PACKAGE}/latest" | jq -r '.version')
fi

echo "Updating claude-code to v${VERSION}"

# Get current version from overlay
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$OVERLAY_FILE" || echo "unknown")
echo "Current version: ${CURRENT_VERSION}"

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
    echo "Already at version ${VERSION}, nothing to do"
    exit 0
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Fetch source hash
echo "Fetching source hash..."
SRC_HASH=$(nix-prefetch-url --unpack "https://registry.npmjs.org/${NPM_PACKAGE}/-/claude-code-${VERSION}.tgz" 2>/dev/null)
SRC_HASH_SRI=$(nix hash convert --hash-algo sha256 "$SRC_HASH")
echo "Source hash: ${SRC_HASH_SRI}"

# Download and extract tarball to generate package-lock.json
echo "Generating package-lock.json..."
curl -sL "https://registry.npmjs.org/${NPM_PACKAGE}/-/claude-code-${VERSION}.tgz" | tar xz -C "$WORKDIR" --strip-components=1

# Generate package-lock.json using npm from nix
nix-shell -p nodejs --run "cd '$WORKDIR' && npm install --package-lock-only --ignore-scripts" 2>/dev/null

if [[ ! -f "${WORKDIR}/package-lock.json" ]]; then
    echo "Error: Failed to generate package-lock.json"
    exit 1
fi

# Copy the lock file to overlays (ensure writable in case previous copy came from nix store)
[[ -f "$LOCKFILE" ]] && chmod u+w "$LOCKFILE"
cp "${WORKDIR}/package-lock.json" "$LOCKFILE"
echo "Updated package-lock.json"

# Compute npmDepsHash using prefetch-npm-deps
echo "Computing npmDepsHash (this may take a minute)..."
NPM_DEPS_HASH=$(nix-shell -p prefetch-npm-deps --run "prefetch-npm-deps '$LOCKFILE'" 2>/dev/null)

if [[ -z "$NPM_DEPS_HASH" ]]; then
    echo "Error: Could not determine npmDepsHash"
    exit 1
fi
echo "npmDepsHash: ${NPM_DEPS_HASH}"

# Update the overlay file
echo "Updating ${OVERLAY_FILE}..."
cat > "$OVERLAY_FILE" << EOF
# Override claude-code to v${VERSION}
# Auto-updated by scripts/update-claude-code.sh
final: prev:
let
  version = "${VERSION}";
  lockfile = ./claude-code-package-lock.json;
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-\${version}.tgz";
    hash = "${SRC_HASH_SRI}";
  };
in
{
  claude-code = prev.claude-code.overrideAttrs (old: {
    inherit version src;
    postPatch = ''
      cp \${lockfile} package-lock.json

      substituteInPlace cli.js \\
            --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';
    npmDeps = old.npmDeps.overrideAttrs {
      inherit src;
      postPatch = ''
        cp \${lockfile} package-lock.json
      '';
      outputHash = "${NPM_DEPS_HASH}";
    };
  });
}
EOF

echo "Done! Updated claude-code overlay to v${VERSION}"
echo "Run 'nixos-rebuild test --flake /etc/nixos#' to test the changes"
