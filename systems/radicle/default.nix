# Run the radicle roles on a host.
#
# The MACHINES are ./seed.nix and ./builder.nix. This file is the other half:
# what any host does to run them. It is here rather than in a host's directory
# because that half is the same everywhere -- an unprivileged account, state
# directories, a decrypted identity, a container -- and only three things
# genuinely differ per host:
#
#   1. WHICH roles it runs. Pass `seed = null` or `builder = null` for the ones
#      it does not.
#   2. THEIR KEYS. Each node needs its own, because a NID lives in the key: two
#      nodes sharing one would both sign the same sigrefs, and Noise XK pins the
#      responder key, so a client dialling that NID could land on either.
#   3. WHAT THE HOST WILL SPEND. Memory and pid ceilings are a property of the
#      machine underneath, not of the role.
#
# So a second host runs the same forge by passing its own keys:
#
#   (import ../radicle { inherit self; } {
#      host = "skyspy-dev";
#      seed.publicKey = "ssh-ed25519 …";
#   })
{ self, tailnet ? "tail46cce1.ts.net" }:

{
  # The host these roles run on. Appears in every node name, because a tailnet
  # name must be unique FLEET-wide and tailscale does not reject a collision --
  # it silently appends -1, leaving two hosts' roles indistinguishable in the
  # one place you would look to tell them apart.
  host

  # Null for a host that does not run one. Otherwise at minimum a publicKey;
  # see the option defaults below for the rest.
, seed ? null
, builder ? null

  # The seed a builder dials, as `<nid>@<host>:<port>`. Usually this host's own
  # seed, but a builder may dial another host's -- so it is named rather than
  # assumed. Expensive to get wrong: the broker watches its OWN node's event
  # stream, so a builder whose seed is unreachable fetches nothing, sees no
  # announcements and never triggers a build, sitting there `active` with an
  # empty CI history.
, builderDialsSeed ? null
}:

{ lib, ... }:

let
  seedName = "radicle-${host}-seed";
  lane = builder.lane or "x64";
  builderName = "radicle-${host}-${lane}-builder";

  # Decrypt this node's key into the identity directory. Written to a temporary
  # name and renamed, so a reader sees either the old file or the new one and
  # never a half-written key.
  #
  # 0444 is deliberate rather than sloppy: a service inside reads its keystore
  # AFTER dropping privileges, and the host's role account maps to container
  # ROOT, so a 0400 file owned by it is unreadable to the one process that needs
  # it. The directory above is 0711 and owned by an account nothing else uses,
  # so nothing on the host gains access.
  decryptKey = ''
    SOPS_AGE_KEY_FILE="$IDENTITY_DIR/age.key" \
      sops --decrypt --extract '["radicle"]["node-key"]' \
      "$IDENTITY_DIR/secrets.yaml" > "$IDENTITY_DIR/.node-key.new"
    chmod 0444 "$IDENTITY_DIR/.node-key.new"
    mv -f "$IDENTITY_DIR/.node-key.new" "$IDENTITY_DIR/node-key"
    chmod 0400 "$IDENTITY_DIR/age.key" "$IDENTITY_DIR/secrets.yaml"
  '';

  # ONE definition per role, used by BOTH the machine (which bakes the path in,
  # since the node reads its key from it) and the hosting (which bind-mounts
  # it). Deriving it twice is what once made a role look for a key nothing
  # mounted, and exit 243/CREDENTIALS.
  seedIdentity = seed.identityDir or "/var/lib/${seedName}-identity";
  builderIdentity = builder.identityDir or "/var/lib/${builderName}-identity";
in
{
  my.infra.ociRoles =
    lib.optionalAttrs (seed != null)
      {
        ${seedName} = {
          system = import ./seed.nix { inherit self tailnet; } ({
            inherit host;
            identityDir = seedIdentity;
            inherit (seed) publicKey;
            # A seed is DIALED. Empty for the only seed on a fleet; when a second
            # exists each lists the other, so the pair re-forms whichever restarts.
            connect = seed.connect or [ ];
          } // lib.optionalAttrs (seed ? ciReportsFrom) { inherit (seed) ciReportsFrom; }
          // lib.optionalAttrs (seed ? avatarDefault) { inherit (seed) avatarDefault; }
          // lib.optionalAttrs (seed ? avatarsByEmail) { inherit (seed) avatarsByEmail; });

          user = seed.user or "${seedName}-forge";
          identityDir = seedIdentity;
          identityScript = decryptKey;
          # Where this node's state ALREADY is. Not an implementation detail:
          # pointing it elsewhere mounts an empty directory and strands the
          # storage and tailnet registration at the old path, so the node comes up
          # holding nothing and re-registers under a new identity.
          stateDir = seed.stateDir or "/var/lib/radicle-roles/${seedName}";
          stateVolumes = {
            radicle = "/var/lib/radicle";
            tailscale = "/var/lib/tailscale";
          };
          memory = seed.memory or "4g";
          pidsLimit = seed.pidsLimit or 2048;
        };
      }
    // lib.optionalAttrs (builder != null) {
      ${builderName} = {
        system = import ./builder.nix { inherit self; } {
          inherit host lane;
          identityDir = builderIdentity;
          inherit (builder) publicKey;
          connect = [ builderDialsSeed ];
        };

        # A SEPARATE account from the seed's, and that is a boundary rather than
        # tidiness: a builder runs repository-supplied shell, so an escape from
        # it must not reach the seed's identity directory or its podman socket.
        # Rootless podman gives an account one storage tree, one subuid range
        # and one control surface.
        user = builder.user or "${builderName}-forge";
        identityDir = builderIdentity;
        identityScript = decryptKey;
        stateDir = builder.stateDir or "/var/lib/radicle-roles/${builderName}";
        stateVolumes = {
          radicle = "/var/lib/radicle";
          radicle-ci = "/var/lib/radicle-ci";
          tailscale = "/var/lib/tailscale";
        };
        # A CI recipe can fork-bomb or exhaust memory; nothing else addresses
        # denial of service against the host itself.
        memory = builder.memory or "16g";
        pidsLimit = builder.pidsLimit or 4096;
      };
    };
}
