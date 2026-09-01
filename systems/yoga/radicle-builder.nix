# The radicle CI builder, as a container role on yoga.
#
# BOOTSTRAP GATE, the same shape as ./radicle.nix. Everything below is inert
# until `enable` flips, and flipping it needs key material only a human can
# mint:
#
#   1. A radicle node key for the builder. DISPOSABLE by design -- that is the
#      property that makes a compromised CI recipe survivable, and it is why a
#      builder gets its own key rather than borrowing the seed's:
#
#        export RAD_HOME=$(mktemp -d) RAD_PASSPHRASE=
#        rad auth --alias radicle-x64-builder
#        rad self --nid                  # -> the builder NID
#        cat $RAD_HOME/keys/radicle.pub  # -> publicKey below, STRIP the comment
#        # private half -> /var/lib/radicle-identity/ (see below), then
#        rm -rf $RAD_HOME
#
#   2. NOTHING. The tailnet node is authenticated the way every other machine
#      on this fleet is -- interactively, once. yoga and aether5d-dev carry no
#      auth key either. `tailscaleAuthKeyFile` is left null, which the role
#      documents as "leaves the node to a manual `tailscale up`", and the
#      registration then PERSISTS (see the tailscale volume below), so this is
#      a one-time step rather than a per-rebuild one.
#
# WHERE THE KEYS GO, AND WHY NOT ~/.secrets.
#
# `~/.secrets` is a PATH flake input: nix copies its entire contents into
# /nix/store, which is world-readable (drwxrwxr-t) and permanent. Anything put
# there is readable by every user and every process on this machine --
# including whatever a CI recipe runs. The identity for a role therefore does
# NOT go there. It goes to a runtime directory this host owns:
#
#     /var/lib/radicle-identity/age.key       0400 radicle-forge
#     /var/lib/radicle-identity/secrets.yaml  0400 radicle-forge
#
# bind-mounted into the container. mynixos' roles/radicle/identity.nix is built
# around exactly this: the image is identity-FREE, and the container is
# identified. One image serves every builder; swapping the key is swapping a
# file, with no rebuild.
#
# A role with no identity does not come up as nobody -- radicle-node exits
# 243/CREDENTIALS and stays down. Verified.
{ config, lib, pkgs, self, ... }:

let
  enable = false; # GATE SHUT -- needs the two keys above

  lane = "x64";
  name = "radicle-${lane}-builder";
  identityDir = "/var/lib/radicle-identity";
  stateDir = "/var/lib/radicle-roles/${name}";
  forgeUser = "radicle-forge";

  # The role, instantiated with THIS fleet's identity. Not the flake's
  # `packages.*` reference images -- those are built for keys whose private
  # halves were destroyed and are tagged `reference` so they cannot be mistaken
  # for a deployment.
  role = self.lib.roles.radicle.builder {
    system = "x86_64-linux";
    inherit lane identityDir;

    # Minted 2026-09-01 for this host. NID z6Mkqfe9hRoi8VyyEZ2GMADdA7BBpxYg59zwVzeFRZ8x8kni.
    # Disposable by design: if a CI recipe ever walks off with it, mint another
    # and the fleet is unaffected -- that property is the whole reason a builder
    # does not borrow the seed's key.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKachTqXzoVtVH9Wxb/TWjJWdnxPZkKbtaitFTJbPNRP";

    # The delegates whose pushes may trigger CI. The builder runs their shell,
    # so this list is the only thing between a hostile patch and code execution
    # here. logger@yoga, as ./radicle.nix already trusts.
    trustedNids = [ "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU" ];

    # The seed this builder dials. It DIALS OUT and is never dialed, so it
    # advertises nothing and needs no inbound reachability at all.
    connect = [ "z6MkqSoohjxUYVfQRqFxCKeRGSJeE8D5dTxkBe8neHWt6Rb1@yoga.tail46cce1.ts.net:8776" ];

  };
in
{
  config = lib.mkIf enable {
    # The forge runs under its OWN identity: not root, and never logger. A
    # podman bug then costs this account rather than the machine, and logger's
    # rootless podman shares no storage, no subuid range and -- podman having no
    # daemon -- no control surface with it. `linger` because the container is a
    # system service that must come up at boot with nobody logged in;
    # oci-containers orders itself after linger-users.service when it sees a
    # non-root podman.user.
    users.users.${forgeUser} = {
      isSystemUser = true;
      group = forgeUser;
      uid = 989; # static: sdnotify=healthy needs a known uid
      home = "/var/lib/${forgeUser}";
      createHome = true;
      linger = true;
      autoSubUidGidRange = true; # rootless podman maps into a subordinate range
    };
    # gid pinned for the same reason as uid, plus one more: the identity files
    # must be owned by this account BEFORE it exists, because the container that
    # creates it is the same container that needs them. A numeric chown works;
    # a name-based one cannot.
    users.groups.${forgeUser} = { gid = 989; };

    # Directories this host owns, created before the container starts. The
    # identity dir is 0700 and holds the key material; the state dirs are what
    # the role keeps across container recreation -- and oci-containers runs
    # `podman rm -f` in its pre-start, so the container IS recreated on every
    # image change.
    systemd.tmpfiles.rules = [
      "d ${identityDir} 0700 ${forgeUser} ${forgeUser} -"
      "d /var/lib/radicle-roles 0755 root root -"
      "d ${stateDir} 0700 ${forgeUser} ${forgeUser} -"
      "d ${stateDir}/radicle 0700 ${forgeUser} ${forgeUser} -"
      "d ${stateDir}/radicle-ci 0700 ${forgeUser} ${forgeUser} -"
      "d ${stateDir}/tailscale 0700 ${forgeUser} ${forgeUser} -"
    ];

    # Persistence is stated HERE, not inherited from my/dev/development. That
    # module writes /var/lib/containers under `my.dev.enable`, and the forge
    # must not depend on a developer-tooling flag -- a host with my.dev.enable =
    # false must still run a builder. Unpersisted, a reboot loses the node
    # identity, the tailnet identity and the CI history together, silently and
    # only on reboot.
    my.system.persistence.features.systemDirectories = [
      "/var/lib/containers" # podman: images, volumes, container state
      "/var/lib/${forgeUser}" # the forge user's own rootless storage
      identityDir
      stateDir
    ];

    virtualisation.oci-containers = {
      backend = "podman";
      containers.${name} = {
        # The image is streamed straight from the role -- no registry, no
        # tarball in the store.
        imageStream = role.config.system.build.image;
        image = "${name}:latest";

        podman.user = forgeUser;

        volumes = [
          "${identityDir}:${identityDir}:ro"
          "${stateDir}/radicle:/var/lib/radicle"
          "${stateDir}/radicle-ci:/var/lib/radicle-ci"

          # The tailnet identity. NOT optional: oci-containers runs `podman rm -f`
          # in its pre-start, so the container is destroyed on every image change
          # -- and on nixos-unstable the image moves whenever the closure does.
          # Unpersisted, the node would have to be re-authenticated by hand after
          # every rebuild, and would leave a trail of dead nodes in the tailnet.
          "${stateDir}/tailscale:/var/lib/tailscale"
        ];

        extraOptions = [
          # NET_ADMIN is NOT optional and NOT only for tailscaled: nixpkgs'
          # firewall.service carries ConditionCapability=CAP_NET_ADMIN, and
          # systemd SKIPS a unit whose condition is unmet rather than failing
          # it. Without this the role comes up reporting `running`, with zero
          # failed units and an EMPTY ruleset. platforms/oci.nix's
          # firewall-enforced unit turns that silence into a failure, so a
          # missing capability is now loud rather than invisible.
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--device=/dev/net/tun"

          # SYS_ADMIN is deliberately NOT granted. A builder runs
          # repository-supplied shell; that is the whole reason it is a separate
          # role with a disposable key.
          "--security-opt=no-new-privileges"
          "--userns=auto" # a distinct range per container, so builders are isolated from each other too

          # A CI recipe can fork-bomb or exhaust memory. Nothing else here
          # addresses denial of service against yoga itself.
          "--pids-limit=4096"
          "--memory=16g"
          "--memory-swap=16g"
        ];
      };
    };
  };
}
