#!/usr/bin/env bash
# Update overlays/claude-code.nix to a claude-code release.
#
# Runs on Linux and macOS alike -- curl, jq and a POSIX userland, nothing
# else. Its predecessor did not: it read the current version with `grep -oP`,
# which BSD grep does not have, and it recomputed the hash itself by handing
# nix-prefetch-url a 300 MB tarball. All that is fetched now is the 2 KB
# release manifest, which already carries a checksum per platform.

set -euo pipefail

BASE_URL="https://downloads.claude.ai/claude-code-releases"

# -P and the discarded stdout matter: `cd` echoes its destination when CDPATH
# resolved it, and that echo would otherwise land inside SCRIPT_DIR.
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" >/dev/null && pwd)"
OVERLAY_FILE="${SCRIPT_DIR}/../overlays/claude-code.nix"

usage() {
    cat <<'USAGE'
Usage: update-claude-code.sh [-f|--force] [latest|stable|<version>]

  (no argument)   whatever upstream currently calls latest
  stable          the stable channel, which trails latest
  <version>       an exact version, e.g. 2.1.234

  -f, --force     rewrite the overlay even if it already pins that version
USAGE
}

FORCE=0
REQUESTED=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -f | --force)
        FORCE=1
        ;;
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

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: $tool is required but not on PATH" >&2
        exit 1
    fi
done

# `latest` and `stable` are channel pointers upstream publishes alongside the
# releases; anything else is taken as a literal version.
REQUESTED="${REQUESTED:-latest}"
case "$REQUESTED" in
latest | stable)
    echo "Resolving the ${REQUESTED} release..."
    if ! VERSION="$(curl -fsSL "${BASE_URL}/${REQUESTED}")"; then
        echo "error: could not reach ${BASE_URL}/${REQUESTED}" >&2
        exit 1
    fi
    ;;
*)
    VERSION="$REQUESTED"
    ;;
esac

# =~ and not grep: grep anchors per line, so a multi-line channel response
# would pass on the strength of one good line and then corrupt a URL.
if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "error: '${VERSION}' does not look like a version" >&2
    exit 1
fi

# The overlay is generated, so its own `version =` line is the current pin.
# It is also regenerable from nothing, so a missing file is not an error.
CURRENT_VERSION=""
if [[ -f "$OVERLAY_FILE" ]]; then
    CURRENT_VERSION="$(awk -F'"' '/^ *version = "/ { print $2; exit }' "$OVERLAY_FILE")"
fi
echo "Current version: ${CURRENT_VERSION:-unknown}"

if [[ "$VERSION" == "$CURRENT_VERSION" && $FORCE -eq 0 ]]; then
    echo "Already at ${VERSION}, nothing to do (--force rewrites anyway)"
    exit 0
fi

echo "Fetching the manifest for ${VERSION}..."
if ! MANIFEST="$(curl -fsSL "${BASE_URL}/${VERSION}/manifest.json")"; then
    echo "error: no release manifest for ${VERSION} -- is that a real release?" >&2
    exit 1
fi

MANIFEST_VERSION="$(printf '%s' "$MANIFEST" | jq -r '.version')"
if [[ "$MANIFEST_VERSION" != "$VERSION" ]]; then
    echo "error: asked for ${VERSION}, manifest says ${MANIFEST_VERSION}" >&2
    exit 1
fi

# One line per platform, sorted. The manifest is a remote document on someone
# else's schedule, so it is checked rather than trusted: a checksum jq cannot
# find renders as the literal string "null", which is valid Nix, sails past
# the parse gate below, and surfaces only as a failed build -- on the Mac,
# only at darwin-rebuild switch. The three required keys are the ones
# hostPlatform.node can actually produce for the platforms this derivation
# supports; the rest of the manifest is mirrored but never selected.
if ! PLATFORMS="$(printf '%s' "$MANIFEST" | jq -er '
    (.platforms // error("no platforms object"))
    | to_entries
    | (["darwin-arm64", "linux-arm64", "linux-x64"] - map(.key)) as $missing
    | if ($missing | length) > 0
      then error("missing platform(s): \($missing | join(", "))")
      else . end
    | map(
        if (.value.checksum // "") | test("^[0-9a-f]{64}$") then .
        else error("checksum for \(.key) is not a sha256") end
      )
    | sort_by(.key)
    | map("        \"\(.key)\".checksum = \"\(.value.checksum)\";")
    | join("\n")
')"; then
    echo "error: the ${VERSION} manifest is not usable (see above)" >&2
    exit 1
fi

# Written aside and moved into place only once it parses, so a botched
# template cannot leave the flake unevaluable.
STAGED="${OVERLAY_FILE}.new"
trap 'rm -f "$STAGED"' EXIT

echo "Writing ${OVERLAY_FILE}..."
cat >"$STAGED" <<EOF
# claude-code pinned to ${VERSION}, overriding whatever the nixpkgs pin ships.
# Auto-updated by scripts/update-claude-code.sh; edit that, not this file.
#
# Upstream ships one native binary per platform plus a release manifest
# listing their checksums, and the nixpkgs derivation takes that manifest as
# an argument. So a version bump overrides exactly one thing: no hand-rolled
# derivation, no per-platform wrapping to keep in sync with upstream's, and
# one overlay that serves x86_64-linux and aarch64-darwin alike -- all three
# hosts import it, and all three land on the same version.
#
# The derivation reads two things out of a manifest: \`version\`, which is also
# half the download URL, and \`platforms.<key>.checksum\`. Both are mirrored
# below; upstream's \`binary\` and \`size\` are dropped. <key> comes from
# hostPlatform.node, which encodes OS and CPU but not libc, so only
# darwin-arm64, linux-arm64 and linux-x64 can ever be selected here -- the
# musl and win32 rows are mirrored for fidelity and are unreachable.
#
# The Linux binaries are Bun single-file executables, but not the appended
# kind: the payload is a mapped .bun section, and the section header table
# ends exactly at EOF with nothing following it (measured on the linux-x64
# artifact). So the patchelf upstream runs on every ELF has no end-of-file
# offset to disturb, and this overlay no longer hand-rolls a derivation to
# route around one, as its predecessor did on that theory. What upstream does
# guard against is stripping, which it says leaves Bun running as a plain
# runtime instead of the app: hence dontStrip, plus a \`claude --version\`
# check against the packaged version at build time, so a binary broken that
# way fails the build rather than reaching a shell.
#
# To wind this down once the nixpkgs pin catches up, delete this file and
# every \`(import ../../overlays/claude-code.nix)\` line under systems/ --
# yoga, skyspy-dev and aether5d-dev today.
_final: prev:
{
  claude-code = prev.claude-code.override {
    manifest = {
      version = "${VERSION}";
      platforms = {
${PLATFORMS}
      };
    };
  };
}
EOF

if command -v nix-instantiate >/dev/null 2>&1; then
    nix-instantiate --parse "$STAGED" >/dev/null
fi
# The staged file carries the caller's umask, and mv is a rename, so set the
# mode explicitly -- git tracks only the executable bit and would not show it.
chmod 644 "$STAGED"
mv "$STAGED" "$OVERLAY_FILE"

echo "Done: claude-code overlay now at ${VERSION}"
echo "Run 'rebuild-system' to apply"
