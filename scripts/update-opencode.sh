#!/usr/bin/env bash
# Update opencode overlay to the latest version
# Usage: ./scripts/update-opencode.sh [version]
# If no version is provided, fetches the latest release from GitHub

set -euo pipefail

OVERLAY_FILE="$(dirname "$0")/../overlays/opencode.nix"
REPO="anomalyco/opencode"

# Get version (from argument or latest release)
if [[ $# -ge 1 ]]; then
    VERSION="$1"
else
    echo "Fetching latest version from GitHub..."
    VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
fi

echo "Updating opencode to v${VERSION}"

# Get current version from overlay
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' "$OVERLAY_FILE" || echo "unknown")
echo "Current version: ${CURRENT_VERSION}"

if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
    echo "Already at version ${VERSION}, nothing to do"
    exit 0
fi

# Fetch source hash
echo "Fetching source hash..."
SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/${REPO}/archive/refs/tags/v${VERSION}.tar.gz" 2>/dev/null)
SRC_HASH_SRI=$(nix hash convert --hash-algo sha256 "$SRC_HASH")
echo "Source hash: ${SRC_HASH_SRI}"

# Build with fake node_modules hash to get the real one
echo "Computing node_modules hash (this may take a minute)..."
NODE_MODULES_HASH=$(nix build --impure --no-link --expr "
let
  pkgs = import <nixpkgs> {};
  version = \"${VERSION}\";
  src = pkgs.fetchFromGitHub {
    owner = \"anomalyco\";
    repo = \"opencode\";
    tag = \"v\${version}\";
    hash = \"${SRC_HASH_SRI}\";
  };
in
pkgs.opencode.overrideAttrs (old: {
  inherit version src;
  node_modules = old.node_modules.overrideAttrs {
    inherit version src;
    outputHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
  };
})
" 2>&1 | grep -oP 'got:\s+\K\S+' || echo "")

if [[ -z "$NODE_MODULES_HASH" ]]; then
    echo "Error: Could not determine node_modules hash"
    exit 1
fi
echo "Node modules hash: ${NODE_MODULES_HASH}"

# Update the overlay file
echo "Updating ${OVERLAY_FILE}..."
cat > "$OVERLAY_FILE" << EOF
# Override opencode to v${VERSION}
# Auto-updated by scripts/update-opencode.sh
final: prev:
let
  version = "${VERSION}";
  src = prev.fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v\${version}";
    hash = "${SRC_HASH_SRI}";
  };
in
{
  opencode = prev.opencode.overrideAttrs (old: {
    inherit version src;
    node_modules = old.node_modules.overrideAttrs {
      inherit version src;
      outputHash = "${NODE_MODULES_HASH}";
    };
  });
}
EOF

echo "Done! Updated opencode overlay to v${VERSION}"
echo "Run 'nixos-rebuild test --flake /etc/nixos#' to test the changes"
