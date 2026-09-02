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
{ lib, pkgs, self, ... }:

let
  # GATE OPEN 2026-09-01. The identity is installed at /var/lib/radicle-identity
  # (0400, owned by the forge user); the tailnet node authenticates once,
  # interactively.
  enable = true;

  lane = "x64";
  # The host is in the name because a tailnet name must be unique FLEET-wide and
  # tailscale does not reject a collision -- it silently appends -1, so two
  # hosts. builders become indistinguishable in the one place you would look to
  # tell them apart.
  name = "radicle-yoga-${lane}-builder";
  identityDir = "/var/lib/radicle-identity";
  stateDir = "/var/lib/radicle-roles/${name}";
  forgeUser = "radicle-forge";

  # The image tag, defined ONCE because it is named in two places that must
  # agree: the role builds the image with it, and the container asks podman for
  # it by name. `my.system.ociImage.tag` defaults to "reference" on purpose --
  # that marks the flake.s reference fleet, built for keys whose private halves
  # were destroyed, and its own description says a real deployment sets this.
  # Naming the host is what distinguishes THIS deployment.s image from another
  # host.s image of the same role, since the repository half is the role name.
  imageTag = "yoga";

  # The role, instantiated with THIS fleet's identity. Not the flake's
  # `packages.*` reference images -- those are built for keys whose private
  # halves were destroyed and are tagged `reference` so they cannot be mistaken
  # for a deployment.
  role = self.lib.roles.radicle.builder {
    system = "x86_64-linux";
    inherit lane identityDir name;

    # Minted 2026-09-01 for this host. NID z6MkmxuVjqGZx3pCC8NUmNMofbJMzEygpX8aZC2fs6SXQ6fb.
    # Disposable by design: if a CI recipe ever walks off with it, mint another
    # and the fleet is unaffected -- that property is the whole reason a builder
    # does not borrow the seed's key.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+Z/2uDBYlhSj6dsI4s7KqOcs0/HBxZX8rIBe/ROzDK";

    # The delegates whose pushes may trigger CI. The builder runs their shell,
    # so this list is the only thing between a hostile patch and code execution
    # here. logger@yoga, as ./radicle.nix already trusts.
    trustedNids = [ "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU" ];

    # The seed this builder dials. It DIALS OUT and is never dialed, so it
    # advertises nothing and needs no inbound reachability at all.
    connect = [ "z6MkqSoohjxUYVfQRqFxCKeRGSJeE8D5dTxkBe8neHWt6Rb1@yoga.tail46cce1.ts.net:8776" ];

    my = [{
      system.ociImage.tag = imageTag;

      # The repositories this builder runs CI for, named ONE BY ONE.
      #
      # The broker watches its OWN node's event stream, so a repository the node
      # does not seed produces no events and never triggers a build -- the
      # builder would sit there looking healthy and do nothing. Seeding is what
      # subscribes it.
      #
      # Explicit rather than `defaultSeedingPolicy = "allow"`: a builder has no
      # reason to hold the fleet's refs, and every repository it seeds is one
      # whose CI recipe it will execute. That list should be a decision, not a
      # side effect of what happens to be announced.
      #
      # scope = "all" because the point is to build what OTHER peers push, not
      # only what this node follows.
      infra.radicle.seedRepositories = [
        { rid = "rad:z2WxYCuLx8F8r2bPLPNjjboGM7qPU"; scope = "all"; } # secure-sweep-mobile
        { rid = "rad:z4KpNmJDpSD4xYHcsASaWa9y3AKTd"; scope = "all"; } # radicle-ci-smoke
      ];
    }];
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
      # NO STATIC uid. Let NixOS allocate one -- it knows what is already
      # taken, and a hand-picked number does not. A pin of 989 here was
      # silently shared with usbmux, which had been allocated it dynamically
      # first; NixOS does not reject a duplicate, so the two accounts simply
      # became one principal. Nothing needs the number to be predictable:
      # every directory is owned through systemd-tmpfiles BY NAME, and the
      # identity files are re-owned by name on every start of the identity
      # unit below.
      home = "/var/lib/${forgeUser}";
      createHome = true;
      linger = true;
      autoSubUidGidRange = true; # rootless podman maps into a subordinate range
    };
    users.groups.${forgeUser} = { };

    # Directories this host owns, created before the container starts. The
    # identity dir is 0700 and holds the key material; the state dirs are what
    # the role keeps across container recreation -- and oci-containers runs
    # `podman rm -f` in its pre-start, so the container IS recreated on every
    # image change.
    systemd.tmpfiles.rules = [
      # These run AFTER the impermanence bind mounts, which is the whole point.
      # A persisted directory starts as an EMPTY root:root backing under /persist,
      # and it is mounted OVER whatever activation created -- so `createHome` and
      # anything else made at activation time is shadowed, not inherited. Without
      # a rule per directory the forge gets a home it cannot write, and rootless
      # podman fails with `stat .../.config: no such file or directory`, which
      # names neither the mount nor the ownership that actually caused it.
      "d /var/lib/${forgeUser} 0700 ${forgeUser} ${forgeUser} -"
      # 0711, not 0700: TRAVERSABLE but not listable. radicle-node reads the
      # key as User=radicle inside the container, and this host's forge uid
      # maps to container root -- so a 0700 directory blocks it at the PATH
      # even when the file itself is readable. That failure is indistinguishable
      # from a bad file mode: both are `Permission denied` on the same open().
      #
      # 0711 lets a process that already knows the filename reach it and
      # nothing else: age.key and secrets.yaml stay 0400, so they remain
      # unreadable to everyone but the owner. Only node-key is 0444, and only
      # deliberately.
      "d ${identityDir} 0711 ${forgeUser} ${forgeUser} -"
      "d /var/lib/radicle-roles 0755 root root -"
      "d ${stateDir} 0700 ${forgeUser} ${forgeUser} -"
      # Owned by the FORGE USER, and that is load-bearing in a way that is easy
      # to get backwards -- I did, once in each direction.
      #
      # Rootless podman maps this host account to container ROOT and its
      # subuids to 1..65536. Host root maps to NOTHING, so a root-owned
      # directory here shows up inside as an unmapped owner and the container
      # cannot chown it at all. Owned by the forge user it arrives as root
      # inside, which is exactly what systemd needs to hand it to its own
      # radicle user via StateDirectory.
      #
      # What must NOT happen is a RECURSIVE chown (`Z`) over these trees. The
      # files underneath belong to the container's users, mapped into the
      # subuid range; rewriting them to the forge user makes them root inside
      # and radicle-node loses its own state after dropping privileges. Create
      # the directory with an owner, never rewrite what is in it.
      "d ${stateDir}/radicle 0700 ${forgeUser} ${forgeUser} -"
      "d ${stateDir}/radicle-ci 0700 ${forgeUser} ${forgeUser} -"
      "d ${stateDir}/tailscale 0700 ${forgeUser} ${forgeUser} -"

      # `d` creates a directory and owns THE DIRECTORY. It does not touch what
      # is inside, so after the account's uid changed, every file underneath
      # still belonged to the old number and rootless podman failed with
      # `path ".../.config" exists and it is not owned by the current user` --
      # which names neither the uid nor the change that caused it.
      #
      # `Z` adjusts ownership RECURSIVELY. Mode is `-` deliberately: these trees
      # hold podman's storage and a mode applied recursively would make every
      # ONLY the forge user's own tree. This is podman's storage, which really
      # does belong to that account on this host, so owning it recursively is
      # right and heals a uid change.
      "Z /var/lib/${forgeUser} - ${forgeUser} ${forgeUser} -"

      # NOT the state volume. Its contents belong to the CONTAINER's users, which
      # rootless podman maps into a subordinate uid range -- they are not this
      # host's account wearing a different hat. Chowning them to the forge user
      # makes them appear as root INSIDE the container, and radicle-node reads
      # its keystore after dropping to User=radicle, so it loses access to its
      # own key:
      #
      #     Unlocking node keystore.. Permission denied (os error 13)
      #
      # It fails in the least helpful way possible: the container starts, the
      # node crash-loops, `systemctl --failed` stays empty because a unit in
      # auto-restart is `activating`, and the visible symptom is a closed port.
      # A rule here also re-breaks it on every rebuild, so it reads as "the last
      # change did this" no matter which change it was.
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

    # The host decrypts, because the container cannot. sops-install-secrets
    # mounts a ramfs for its secrets directory and that needs CAP_SYS_ADMIN,
    # which a role running repository-supplied shell must not have. This host
    # does have it, so the key is decrypted here, once, into the directory that
    # is bind-mounted read-only into the container.
    #
    # The plaintext lands beside the ciphertext at 0400 owned by the forge user.
    # It is written to a temporary name and renamed, so a reader either sees the
    # previous key or the new one, never a half-written file.
    systemd.services = {
      # oci-containers gives a `podman.user` unit a PATH of podman's own bin
      # and nothing else. podman locates its OCI runtime through a helper-binary
      # wrapper that normally sits on the SYSTEM profile PATH, which this unit
      # does not have -- so it fails with
      #     default OCI runtime "crun" not found: invalid argument
      # which reads as a missing package and is a missing PATH entry.
      "podman-${name}".path = [ pkgs.crun ];

      "${name}-identity" = {
        description = "Decrypt the ${name} radicle node key";
        # requiredBy, not wantedBy: a container that starts without its identity
        # does not fail usefully -- radicle-node exits 243/CREDENTIALS from inside
        # a nested boot, where the reason is three logs deep.
        requiredBy = [ "podman-${name}.service" ];
        before = [ "podman-${name}.service" ];
        # After the impermanence bind mount, or this writes to a directory that is
        # about to be hidden underneath one.
        after = [ "systemd-tmpfiles-setup.service" ];
        path = [ pkgs.sops ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          umask 077
          SOPS_AGE_KEY_FILE=${identityDir}/age.key \
            sops --decrypt --extract '["radicle"]["node-key"]' \
            ${identityDir}/secrets.yaml > ${identityDir}/.node-key.new
          chown ${forgeUser}:${forgeUser} ${identityDir}/.node-key.new
          chmod 0444 ${identityDir}/.node-key.new
          mv -f ${identityDir}/.node-key.new ${identityDir}/node-key
  
          # Own the whole directory by NAME on every start. The uid is allocated by
          # NixOS and can change; files chowned to a stale number would leave the
          # role unable to read its own identity, and the symptom would be podman
          # complaining about .config rather than anything naming the key.
          chown -R ${forgeUser}:${forgeUser} ${identityDir}
          chmod 0400 ${identityDir}/age.key ${identityDir}/secrets.yaml

          # The node key is 0444, and that is deliberate rather than sloppy.
          #
          # radicle-node reads its keystore AFTER dropping to User=radicle
          # inside the container. This host's forge uid maps to container
          # ROOT, so a 0400 file owned by it is unreadable to the very process
          # that needs it -- `Unlocking node keystore.. Permission denied`.
          # Upstream avoids this with LoadCredential, which cannot work here:
          # systemd builds the credentials directory by mounting a ramfs.
          #
          # What 0444 widens, precisely: any process INSIDE this container can
          # read the key. On the host nothing changes -- the directory above is
          # 0700 and owned by the forge user, so no other host account can
          # traverse to it. And inside the container the CI adapter could
          # already reach this key: that is the accepted risk this role is
          # designed around, and the reason the key is a BUILDER's and
          # disposable rather than the seed's.
          chmod 0444 ${identityDir}/node-key
          chmod 0711 ${identityDir}
        '';
      };
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.${name} = {
        # The image is streamed straight from the role -- no registry, no
        # tarball in the store.
        imageStream = role.config.system.build.image;
        # `localhost/` is NOT decoration: podman refuses an unqualified short name
        # ("did not resolve to an alias and no unqualified-search registries are
        # defined"), and it would be wrong to define a search registry for an
        # image that is loaded locally and must never be fetched.
        image = "localhost/${name}:${imageTag}";

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
          # systemd as PID 1 needs /run, /run/lock and the cgroup hierarchy set up
          # as tmpfs. podman does that in "systemd mode", which it auto-enables
          # ONLY when the command is literally /sbin/init, /usr/sbin/init,
          # /usr/local/sbin/init or systemd. A NixOS toplevel is a store path
          # ending in /init, which matches none of them -- so it must be forced.
          # Without it systemd execs and dies instantly, printing nothing, which
          # reads as an image problem and is not one.
          "--systemd=always"

          "--security-opt=no-new-privileges"
          # NO --userns=auto. It allocates a FRESH uid range per container, so the
          # host uid that owns the identity files is not mapped inside -- the
          # 0400 bind mount then reads as an unmapped owner and sops-install-secrets
          # fails with `permission denied`, which looks like a mode problem and is
          # not one. Plain rootless podman maps this host user to container root,
          # which is what makes a read-only 0400 mount readable at all.
          #
          # The isolation it was reaching for belongs at a different seam: one
          # forge USER per builder, which separates storage, subuid range and
          # control surface by construction. With a single builder there is
          # nothing yet to isolate from.

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
