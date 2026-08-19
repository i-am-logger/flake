#!/usr/bin/env bash
# Update overlays/herdr.nix to a herdr release, but only when upstream is
# actually ahead of the nixpkgs we build against.
#
# Runs on Linux and macOS alike. Unlike claude-code, herdr is built from
# source and upstream publishes no hashes, so two of the three this script
# needs can only be learned by building: cargoDeps and zigDeps. Each is
# harvested from its own trial build, and the src hash is proven on its own
# first -- otherwise a wrong src hash surfaces as the *cargo* mismatch and
# gets written into the overlay as one, where it parses, formats and
# evaluates cleanly and fails only at build time.

set -euo pipefail

REPO="herdrdev/herdr"
API="https://api.github.com/repos/${REPO}"

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" >/dev/null && pwd)"
FLAKE_DIR="$(cd -P -- "${SCRIPT_DIR}/.." >/dev/null && pwd)"
OVERLAY_FILE="${FLAKE_DIR}/overlays/herdr.nix"

# my.system.localInputs makes the rebuild scripts prefer this checkout over
# the locked input whenever it exists, so the version we must measure against
# is the one that build will see -- not the one flake.lock names. --lock
# forces the locked input, which is what CI should compare against.
LOCAL_MYNIXOS="${HOME}/Code/mynixos"

usage() {
    cat <<'USAGE'
Usage: update-herdr.sh [-f|--force] [--lock] [<version>]

  (no argument)   upstream's latest stable release
  <version>       an exact version, e.g. 0.8.2

  -f, --force     write the overlay even when nixpkgs already has that
                  version, and allow moving the pin backwards
      --lock      measure nixpkgs through flake.lock, ignoring any local
                  mynixos checkout
USAGE
}

FORCE=0
USE_LOCK=0
REQUESTED=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -f | --force) FORCE=1 ;;
    --lock) USE_LOCK=1 ;;
    -*)
        echo "error: unknown option '$1'" >&2
        usage >&2
        exit 2
        ;;
    *)
        if [[ -n "$REQUESTED" ]]; then
            echo "error: expected at most one version" >&2
            usage >&2
            exit 2
        fi
        REQUESTED="$1"
        ;;
    esac
    shift
done

for tool in curl jq nix; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: $tool is required but not on PATH" >&2
        exit 1
    fi
done

# Which nixpkgs the comparison is against. Announced, because measuring the
# wrong one is invisible in the result and changes the verdict.
if [[ $USE_LOCK -eq 0 && -d "$LOCAL_MYNIXOS" ]]; then
    NIXPKGS_EXPR="(builtins.getFlake \"git+file://${LOCAL_MYNIXOS}\").inputs.nixpkgs"
    NIXPKGS_SOURCE="local mynixos checkout (${LOCAL_MYNIXOS})"
else
    NIXPKGS_EXPR="(builtins.getFlake \"${FLAKE_DIR}\").inputs.mynixos.inputs.nixpkgs"
    NIXPKGS_SOURCE="flake.lock"
fi

nix_eval() { nix eval --impure --raw --expr "$1" 2>/dev/null; }

# Latest stable release. Prereleases are herdr's preview-YYYY-MM-DD-<sha>
# builds; /releases/latest already excludes them.
if [[ -n "$REQUESTED" ]]; then
    VERSION="$REQUESTED"
else
    echo "Resolving the latest herdr release..."
    if ! TAG="$(curl -fsSL "${API}/releases/latest" | jq -er '.tag_name')"; then
        echo "error: could not reach ${API}/releases/latest" >&2
        exit 1
    fi
    VERSION="${TAG#v}"
fi

if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "error: '${VERSION}' does not look like a version" >&2
    exit 1
fi

SYSTEM="$(nix_eval 'builtins.currentSystem')"
NIXPKGS_VERSION="$(nix_eval "${NIXPKGS_EXPR}.legacyPackages.${SYSTEM}.herdr.version")"
if [[ -z "$NIXPKGS_VERSION" ]]; then
    echo "error: could not read herdr's version from ${NIXPKGS_SOURCE}" >&2
    exit 1
fi

CURRENT_VERSION=""
if [[ -f "$OVERLAY_FILE" ]]; then
    CURRENT_VERSION="$(awk -F'"' '/^ *version = "/ { print $2; exit }' "$OVERLAY_FILE")"
fi

echo "upstream:  ${VERSION}"
echo "nixpkgs:   ${NIXPKGS_VERSION}  (via ${NIXPKGS_SOURCE})"
echo "overlay:   ${CURRENT_VERSION:-none}"

# The whole point of the overlay is to be ahead of nixpkgs. Once nixpkgs
# catches up it is not merely redundant, it is a downgrade waiting to happen,
# so say so rather than writing one.
# --raw refuses an integer, so this one deliberately does not use nix_eval.
newer() {
    local r
    r="$(nix eval --impure --expr "builtins.compareVersions \"$1\" \"$2\"" 2>/dev/null)"
    [[ "$r" == "1" ]]
}

if [[ $FORCE -eq 0 ]] && ! newer "$VERSION" "$NIXPKGS_VERSION"; then
    echo
    echo "nixpkgs is not behind ${VERSION} -- no overlay needed."
    if [[ -n "$CURRENT_VERSION" ]]; then
        echo "Delete ${OVERLAY_FILE#"$FLAKE_DIR"/} and its import in systems/*/default.nix."
    fi
    exit 0
fi

if [[ -n "$CURRENT_VERSION" && $FORCE -eq 0 ]]; then
    if [[ "$CURRENT_VERSION" == "$VERSION" ]]; then
        echo "Already at ${VERSION}, nothing to do (--force rewrites anyway)"
        exit 0
    fi
    if ! newer "$VERSION" "$CURRENT_VERSION"; then
        echo "error: ${VERSION} is not newer than the pinned ${CURRENT_VERSION}" >&2
        echo "       (--force to move the pin backwards anyway)" >&2
        exit 1
    fi
fi

PROBE="$(mktemp -d)"
trap 'rm -rf "$PROBE"' EXIT

FAKE="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# `nix flake prefetch` gives the fetchFromGitHub hash without a build. herdr
# declares no submodules, so the fetchTree result and fetchFromGitHub's agree
# -- and the src build below is what actually proves that, rather than the
# assumption carrying the script.
echo
echo "Prefetching v${VERSION} source..."
if ! SRC_HASH="$(nix flake prefetch --json "github:${REPO}/v${VERSION}" 2>/dev/null | jq -er '.hash')"; then
    echo "error: could not prefetch github:${REPO}/v${VERSION}" >&2
    exit 1
fi

is_hash() { [[ "$1" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; }

if ! is_hash "$SRC_HASH"; then
    echo "error: prefetch returned '${SRC_HASH}', which is not a sha256-SRI hash" >&2
    exit 1
fi

write_probe() {
    cat >"${PROBE}/probe.nix" <<EOF
let
  prev = ${NIXPKGS_EXPR}.legacyPackages.${SYSTEM};
  version = "${VERSION}";
  src = prev.fetchFromGitHub {
    owner = "${REPO%%/*}";
    repo = "${REPO##*/}";
    tag = "v\${version}";
    hash = "${SRC_HASH}";
  };
in
{
  inherit src;
  cargoDeps = prev.rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "$1";
  };
  zigDeps = prev.zig_0_15.fetchDeps {
    pname = "herdr";
    inherit version;
    src = "\${src}/vendor/libghostty-vt";
    fetchAll = true;
    hash = "$2";
  };
}
EOF
}

# Prove the src hash on its own before anything else is built against it. A
# src mismatch discovered here is reported as a src mismatch; discovered
# later it would be misread as whichever dependent FOD failed first.
write_probe "$FAKE" "$FAKE"
echo "Verifying the source hash..."
if ! nix build --impure --no-link --expr "(import ${PROBE}/probe.nix).src" >/dev/null 2>"${PROBE}/src.log"; then
    echo "error: the prefetched source hash does not build" >&2
    sed -n 's/^ *//p' "${PROBE}/src.log" | head -20 >&2
    exit 1
fi

# Harvest one hash per build, each with every *other* hash already correct, so
# the single mismatch in the log can only be the one being asked for.
harvest() {
    local attr="$1" log="${PROBE}/${1}.log" got
    if nix build --impure --no-link --expr "(import ${PROBE}/probe.nix).${attr}" >/dev/null 2>"$log"; then
        echo "error: ${attr} built with a placeholder hash -- refusing to guess" >&2
        return 1
    fi
    got="$(awk '/got:/ { print $2; exit }' "$log")"
    if ! is_hash "$got"; then
        echo "error: no usable hash in the ${attr} build log:" >&2
        sed -n 's/^ *//p' "$log" | head -20 >&2
        return 1
    fi
    printf '%s' "$got"
}

echo "Vendoring cargo dependencies (this compiles nothing, but downloads a lot)..."
CARGO_HASH="$(harvest cargoDeps)"

write_probe "$CARGO_HASH" "$FAKE"
echo "Fetching zig dependencies..."
ZIG_HASH="$(harvest zigDeps)"

echo
echo "  src       ${SRC_HASH}"
echo "  cargoDeps ${CARGO_HASH}"
echo "  zigDeps   ${ZIG_HASH}"

# Written aside and moved into place only once it parses, so a botched
# template cannot leave the flake unevaluable.
STAGED="${OVERLAY_FILE}.new"
trap 'rm -rf "$PROBE"; rm -f "$STAGED"' EXIT

echo
echo "Writing ${OVERLAY_FILE}..."
cat >"$STAGED" <<EOF
# herdr pinned to ${VERSION}, ahead of the ${NIXPKGS_VERSION} nixpkgs ships.
# Auto-updated by scripts/update-herdr.sh; edit that, not this file.
#
# herdr is built from source, so unlike overlays/claude-code.nix this cannot
# be a one-attribute override. Three things have to move together:
#
#   src        the release tag, and its hash
#   cargoDeps  re-expressed, not inherited. buildRustPackage turns cargoHash
#              into cargoDeps inside its own wrapper, above the finalAttrs
#              fixed point overrideAttrs re-enters, so overriding cargoHash
#              alone leaves the vendor directory built from the old lockfile.
#   zigDeps    re-expressed for the same reason: it is a fixed-output fetch of
#              vendor/libghostty-vt whose hash is a literal in the recipe.
#
# Everything else -- the zig hook wiring, the darwin cctools/xcbuild inputs,
# the shell completions and SKILL.md generated in postInstall -- is inherited
# from nixpkgs, which is the point of overriding rather than vendoring the
# recipe: nixpkgs' fixes keep arriving.
#
# Delete this file and its import in systems/*/default.nix once nixpkgs ships
# ${VERSION} or newer. Running scripts/update-herdr.sh will say so when that day
# comes, and will refuse to write an overlay that is not ahead.
_final: prev:
let
  version = "${VERSION}";

  src = prev.fetchFromGitHub {
    owner = "${REPO%%/*}";
    repo = "${REPO##*/}";
    tag = "v\${version}";
    hash = "${SRC_HASH}";
  };
in
{
  herdr = prev.herdr.overrideAttrs (_old: {
    inherit version src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "${CARGO_HASH}";
    };

    zigDeps = prev.zig_0_15.fetchDeps {
      pname = "herdr";
      inherit version;
      src = "\${src}/vendor/libghostty-vt";
      fetchAll = true;
      hash = "${ZIG_HASH}";
    };
  });
}
EOF

if command -v nix-instantiate >/dev/null 2>&1; then
    nix-instantiate --parse "$STAGED" >/dev/null
fi
chmod 644 "$STAGED"
mv "$STAGED" "$OVERLAY_FILE"

echo "Done: herdr overlay now at ${VERSION}"
echo "Run 'rebuild-system' to apply"
