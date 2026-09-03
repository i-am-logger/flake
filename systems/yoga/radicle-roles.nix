# The radicle roles yoga HOSTS.
#
# The machines themselves are ../radicle/{seed,builder}.nix -- systems in their
# own right, siblings of this host rather than children of it. This file is only
# yoga's side of the arrangement: which roles run here, whose keys they carry,
# and the resource ceilings this machine is willing to give them.
#
# BOOTSTRAP GATE. Everything is inert until `enable` flips, and flipping it
# needs key material only a human can mint. Each node needs its OWN key, because
# a NID lives in the key: two nodes sharing one would both sign the same
# sigrefs, and Noise XK pins the responder key.
#
#   export RAD_HOME=$(mktemp -d) RAD_PASSPHRASE=
#   rad auth --alias <node name>
#   rad node status --only nid      # -> the NID
#   cat $RAD_HOME/keys/radicle.pub  # -> publicKey below, STRIP the comment
#   # private half -> encrypted to the identity dir, then
#   rm -rf $RAD_HOME
#
# WHERE THE KEYS GO, AND WHY NOT ~/.secrets. A `path` flake input is copied into
# /nix/store, which is world-readable and permanent -- and interpolating one
# copies the whole DIRECTORY the named file sits in, publishing whatever else is
# beside it. That is not hypothetical: it is how this fleet's first seed key came
# to sit in the store at mode 0444. Identity goes to a runtime directory this
# host owns, decrypted by the host because a role cannot decrypt for itself.
{ lib, self, ... }:

let
  enable = true;

  tailnet = "tail46cce1.ts.net";
  seedName = "radicle-yoga-seed";
  builderName = "radicle-yoga-x64-builder";

  # The seed's NID, needed by the builder to dial it. Named once here so the two
  # cannot drift: retiring or replacing a seed means repointing everything that
  # dialled it, and a builder whose seed has gone away fails silently.
  seedNid = "z6Mks9Ty1pdeM6LWsivN674EL3s3qCf8aVo8hw9KN3gmSPwW";

  # ONE definition each, used by BOTH the machine (which bakes the path into
  # the role, since the node reads its key from it) and the hosting (which
  # bind-mounts it). Deriving it in two places is what made the role look for a
  # key nothing mounted.
  seedIdentity = "/var/lib/radicle-seed-identity";
  builderIdentity = "/var/lib/radicle-identity";

  # Decrypt one sops value into the identity directory. Written to a temporary
  # name and renamed, so a reader sees either the old file or the new one and
  # never a half-written key.
  #
  # 0444 on the key is deliberate rather than sloppy: a service inside reads its
  # keystore AFTER dropping privileges, and this host's role account maps to
  # container ROOT, so a 0400 file owned by it is unreadable to the one process
  # that needs it. The directory above is 0711 and owned by an account nothing
  # else uses, so nothing on the host gains access.
  decryptKey = ''
    SOPS_AGE_KEY_FILE="$IDENTITY_DIR/age.key" \
      sops --decrypt --extract '["radicle"]["node-key"]' \
      "$IDENTITY_DIR/secrets.yaml" > "$IDENTITY_DIR/.node-key.new"
    chmod 0444 "$IDENTITY_DIR/.node-key.new"
    mv -f "$IDENTITY_DIR/.node-key.new" "$IDENTITY_DIR/node-key"
    chmod 0400 "$IDENTITY_DIR/age.key" "$IDENTITY_DIR/secrets.yaml"
  '';
in
{
  config = lib.mkIf enable {
    my.infra.ociRoles = {
      ${seedName} = {
        system = import ../radicle/seed.nix { inherit self tailnet; } {
          host = "yoga";
          identityDir = seedIdentity;
          # Minted 2026-09-02. NOT disposable: every workstation pins this NID
          # in a `connect` entry, so rotating it means visiting each of them.
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyY9GfELIEcnfz8bAlbPWp68FYgNGADDEPk9J29+3h5";
          # The fleet's only seed, so nothing to dial: a seed is DIALED.
          connect = [ ];
          # Named by the HOST, because the reports exist only on the builder
          # this host also runs. A seed elsewhere proxies its own builder, or
          # none.
          ciReportsFrom = "http://${builderName}.${tailnet}:8782/";
          avatarDefault = ../../users/logger/avatar.png;
          avatarsByEmail."i-am-logger@users.noreply.github.com" = ../../users/logger/avatar.png;
        };
        user = "radicle-seed-forge";
        identityDir = seedIdentity;
        identityScript = decryptKey;
        # THE PATH THE RUNNING NODE'S STATE IS ALREADY AT. Not a default:
        # pointing this elsewhere does not migrate anything, it mounts an empty
        # directory and strands the storage and the tailnet registration at the
        # old location. The node then comes up holding nothing and re-registers
        # under a new tailnet identity -- which is exactly what happened once.
        stateDir = "/var/lib/radicle-roles/${seedName}";
        stateVolumes = {
          radicle = "/var/lib/radicle";
          tailscale = "/var/lib/tailscale";
        };
        memory = "4g";
        pidsLimit = 2048;
      };

      ${builderName} = {
        system = import ../radicle/builder.nix { inherit self; } {
          host = "yoga";
          identityDir = builderIdentity;
          # Minted 2026-09-01. Disposable by design -- a CI recipe can read it,
          # which is the accepted risk that makes a builder a separate role.
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+Z/2uDBYlhSj6dsI4s7KqOcs0/HBxZX8rIBe/ROzDK";
          connect = [ "${seedNid}@${seedName}.${tailnet}:8776" ];
        };
        # A SEPARATE account from the seed's, and that is a boundary rather than
        # tidiness: the builder runs repository-supplied shell, so an escape
        # from it must not reach the seed's identity directory or its podman
        # socket. Rootless podman gives an account one storage tree, one subuid
        # range and one control surface.
        user = "radicle-forge";
        identityDir = builderIdentity;
        identityScript = decryptKey;
        stateDir = "/var/lib/radicle-roles/${builderName}";
        stateVolumes = {
          radicle = "/var/lib/radicle";
          radicle-ci = "/var/lib/radicle-ci";
          tailscale = "/var/lib/tailscale";
        };
        # A CI recipe can fork-bomb or exhaust memory; nothing else here
        # addresses denial of service against yoga itself.
        memory = "16g";
        pidsLimit = 4096;
      };
    };
  };
}
