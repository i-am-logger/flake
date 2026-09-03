# The radicle seed, as a container role HOSTED on yoga.
#
# Hosted, not part of it. This is a machine: its own NID, its own tailnet node,
# its own storage. yoga runs the container and knows nothing else about it,
# which is why this host's configuration no longer contains a radicle service
# of its own.
#
# It arrived as a SECOND seed, beside one that ran on the host directly.
# Radicle's replication model makes seeds PLURAL -- the NID lives in the key,
# not the address -- so adding one was a normal fleet join with nothing
# destructive in it, and retiring the old one was a separate decision taken
# later, once this node had been observed fetching the repositories from it.
#
# NOTHING IS PUBLISHED TO THE HOST, and that is deliberate rather than an
# omission. This container runs its own tailscaled, so it is its own tailnet
# node with its own MagicDNS name, and its ports live in that network
# namespace: the node on 8776, httpd on 8780, the explorer on 8781. While a
# host seed was still running it used those same numbers with no collision, for
# exactly this reason.
#
# Publishing them to the host would be the mistake. It would put a seed behind
# yoga's address, and an address is not an identity here -- a NID is, and it
# lives in the key. Two seeds behind one name is precisely what that makes
# meaningless.
#
# WHY ITS OWN FORGE USER rather than the builder's. Rootless podman gives an
# account one storage tree, one subuid range and one control surface. The
# builder runs repository-supplied shell by design, so anything that escapes it
# lands on the builder's forge user -- and if that account also owned this
# container, the escape would reach the seed's identity directory and its
# podman socket. A builder's key is disposable; a seed's is not. Separate
# accounts make that difference structural instead of a matter of trust.
{ lib, pkgs, self, ... }:

let
  # GATE OPEN 2026-09-02. Key minted, encrypted to a fresh age key, decrypt
  # round-trip verified before the plaintext was shredded; the identity is
  # installed at identityDir below.
  enable = true;

  # The host is in the name for the same reason it is in the builder's: a
  # tailnet name must be unique fleet-wide, and tailscale does not reject a
  # collision -- it silently appends -1, so two hosts' seeds would become
  # indistinguishable in the one place you would look to tell them apart.
  name = "radicle-yoga-seed";
  tailnetName = "${name}.tail46cce1.ts.net";

  identityDir = "/var/lib/radicle-seed-identity";
  stateDir = "/var/lib/radicle-roles/${name}";
  forgeUser = "radicle-seed-forge";

  # Defined once because the role builds the image with it and the container
  # asks podman for it by name; the two must agree, and the default of
  # "reference" marks the flake's reference fleet rather than a deployment.
  imageTag = "yoga";

  # NO PEERS TO DIAL. The host seed this node was stood up beside has been
  # retired, so this is now the fleet's only seed and there is nothing for it
  # to dial: a seed is DIALED, by workstations and by the builder.
  #
  # Emptied rather than left pointing at the retired node. A dead entry is not
  # inert -- radicle retries it forever and fills the log with
  # `Failed to establish connection ... Name or service not known`, which is
  # indistinguishable from a real network fault the next time someone reads
  # these logs looking for one.
  #
  # When a second seed is added back, it goes here.

  role = self.lib.roles.radicle.seed {
    system = "x86_64-linux";
    inherit name identityDir;

    # Minted 2026-09-02 for this host.
    # NID z6Mks9Ty1pdeM6LWsivN674EL3s3qCf8aVo8hw9KN3gmSPwW.
    #
    # NOT disposable, unlike the builder's. Every workstation pins this NID in
    # a `connect` entry, so rotating it means visiting each of them -- which is
    # why this key was minted with a decrypt round-trip verified before the
    # plaintext was destroyed, rather than the builder's lighter ceremony.
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyY9GfELIEcnfz8bAlbPWp68FYgNGADDEPk9J29+3h5";

    # A seed is DIALED, so unlike a builder it must advertise where. This is
    # the container's own tailnet name, not yoga's -- a NID lives in the key,
    # so even when this was one of a pair the two were separate nodes at
    # separate addresses, and collapsing them onto one host name is exactly
    # what a per-key NID exists to prevent.
    connect = [ ];
    externalAddresses = [ "${tailnetName}:8776" ];

    # Baked into the explorer SPA at build time and fetched by the BROWSER, so
    # it has to be a name the browser resolves -- this container's tailnet
    # name, never "localhost" and never yoga's.
    seedHostname = tailnetName;

    my = [{
      system.ociImage.tag = imageTag;

      # `defaultSeedingPolicy = "allow"` (set by the role) accepts what is
      # ANNOUNCED, and an announcement happens on push. The repositories that
      # already exist were pushed before this node existed, so nothing will
      # re-announce them and an empty seed would look healthy forever. Naming
      # them is what makes the node fetch them from the peer it just dialed --
      # and therefore what makes replication observable rather than assumed.
      infra.radicle.seedRepositories = [
        { rid = "rad:z2WxYCuLx8F8r2bPLPNjjboGM7qPU"; scope = "all"; } # secure-sweep-mobile
        { rid = "rad:z4KpNmJDpSD4xYHcsASaWa9y3AKTd"; scope = "all"; } # radicle-ci-smoke
      ];

      # No CI here. CI runs on the builder, which is the only machine its
      # reports exist on; a seed that also built would put repository-supplied
      # shell next to a non-disposable key.

      # THE EXPLORER, restored to what the host seed used to serve. Retiring
      # that seed took its nginx and its `tailscale serve` with it, so until
      # this block existed the forge UI was reachable only over plain http on
      # port 8781 and the CI reports were not reachable at all.
      infra.radicle.httpd.explorer = {
        # HTTPS without running a CA or an ACME client: tailscaled already
        # holds a certificate for this container's own tailnet name, and
        # `serve` terminates TLS with it and proxies to nginx on loopback.
        # Under https the role's nginx binds LOOPBACK ONLY, so `serve` is the
        # single front door rather than a second, unencrypted way in.
        scheme = "https";
        externalPort = 443;

        # CI reports come from wherever CI actually RAN, which is the builder
        # -- the only machine they exist on. Proxying is what avoids matching
        # subuid mappings across a userns boundary by hand to read its files.
        #
        # This is also the failure the option was added for: CI moved to the
        # builder, the host's own ci.enable went false, and the /ci/ location
        # disappeared with it, so the page went blank rather than wrong. It
        # went blank a second time when the host seed was retired, because the
        # proxy lived on that host's nginx. It lives here now, beside the
        # explorer that links to it.
        ciReports.proxyTo = "http://radicle-yoga-x64-builder.tail46cce1.ts.net:8782/";

        # NOT decoration, and not scope creep: without this the explorer bundle
        # calls www.gravatar.com with an md5 of every committer's address. The
        # module rewrites that host to a same-origin /avatars/ path only when
        # avatars are enabled, so leaving it off would have this
        # tailnet-private forge announce who commits to it to a third party on
        # every page view. The host seed carried these for exactly that reason;
        # they have to move with the explorer, not stay behind with it.
        avatars = {
          default = ../../users/logger/avatar.png;
          byEmail."i-am-logger@users.noreply.github.com" = ../../users/logger/avatar.png;
        };
      };
    }];
  };
in
{
  config = lib.mkIf enable {
    users.users.${forgeUser} = {
      isSystemUser = true;
      group = forgeUser;
      # NO STATIC uid -- NixOS knows what is taken and a hand-picked number
      # does not. Everything below owns by NAME, so the number never has to be
      # predictable.
      home = "/var/lib/${forgeUser}";
      createHome = true;
      linger = true;
      autoSubUidGidRange = true; # rootless podman maps into a subordinate range
    };
    users.groups.${forgeUser} = { };

    # ONLY the shared parent, which is not persisted and so has no bind mount to
    # race with. Everything under it is prepared by the unit below instead.
    #
    # WHY NOT TMPFILES, which is what ./radicle-builder.nix uses and what the
    # rest of this repository would lead you to write. tmpfiles rules are
    # applied by systemd-tmpfiles-setup, and on the activation that FIRST
    # introduces a persisted directory the impermanence bind mount does not
    # exist yet -- activation starts tmpfiles-resetup before it starts the new
    # .mount units. The rules therefore land on the pre-mount directory, and
    # the empty root:root 0755 backing from /persist is then mounted straight
    # over the ownership they just set.
    #
    # The builder does not hit this because its mounts already existed by the
    # time its rules were added, so the two have never been in this order
    # there. That is luck, not design: it would hit the next new role too.
    #
    # The symptom is `stat /var/lib/<forge>/.config: no such file or directory`
    # from podman's pre-start, which names neither the mount nor the ownership
    # that caused it, and the unit then trips its start limit and stops
    # retrying -- so it stays failed even after the mount is fine.
    systemd.tmpfiles.rules = [
      "d /var/lib/radicle-roles 0755 root root -"
    ];

    # Stated here rather than inherited from my/dev/development: that module
    # writes /var/lib/containers under `my.dev.enable`, and a seed must not
    # depend on a developer-tooling flag. Unpersisted, a reboot loses the node
    # identity, the tailnet identity and the replicated storage together --
    # silently, and only on reboot.
    my.system.persistence.features.systemDirectories = [
      "/var/lib/containers"
      "/var/lib/${forgeUser}"
      identityDir
      stateDir
    ];

    systemd.services = {
      # oci-containers gives a `podman.user` unit a PATH of podman's own bin and
      # nothing else, so podman cannot find its OCI runtime and fails with
      # `default OCI runtime "crun" not found` -- which reads as a missing
      # package and is a missing PATH entry.
      "podman-${name}".path = [ pkgs.crun ];

      "${name}-identity" = {
        description = "Prepare ${name}'s state directories and decrypt its node key";
        # requiredBy, not wantedBy: a container that starts without its identity
        # does not fail usefully -- radicle-node exits 243/CREDENTIALS from
        # inside a nested boot, where the reason is three logs deep.
        requiredBy = [ "podman-${name}.service" ];
        before = [ "podman-${name}.service" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        # THE ORDERING THAT MATTERS, and the reason directory preparation lives
        # in this unit rather than in tmpfiles: RequiresMountsFor makes systemd
        # pull in and wait for the impermanence bind mounts covering these
        # paths. Everything below therefore writes to the persisted directory
        # rather than to the one about to be hidden underneath it -- which is
        # exactly the race tmpfiles loses on a first activation.
        unitConfig.RequiresMountsFor = [
          "/var/lib/${forgeUser}"
          stateDir
          identityDir
        ];
        path = [ pkgs.sops ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          umask 077

          # `install -d` sets mode and owner on a directory that already
          # exists, so this is idempotent and also heals a uid change.
          #
          # Owned by the FORGE USER, not root, and that is load-bearing in a
          # way that is easy to get backwards. Rootless podman maps this host
          # account to container ROOT and its subuids to 1..65536; host root
          # maps to NOTHING, so a root-owned directory arrives inside with an
          # unmapped owner and the container cannot chown it at all.
          install -d -m 0700 -o ${forgeUser} -g ${forgeUser} /var/lib/${forgeUser}
          install -d -m 0700 -o ${forgeUser} -g ${forgeUser} ${stateDir}
          install -d -m 0700 -o ${forgeUser} -g ${forgeUser} ${stateDir}/radicle
          install -d -m 0700 -o ${forgeUser} -g ${forgeUser} ${stateDir}/tailscale

          # Recursive over the forge user's OWN podman storage, which really
          # does belong to this account on this host and which a uid change
          # would otherwise strand.
          #
          # Never over ${stateDir}: those files belong to the CONTAINER's
          # users, mapped into a subordinate range. Rewriting them to the forge
          # user makes them root INSIDE, and radicle-node reads its keystore
          # after dropping to User=radicle -- so it loses its own key and
          # crash-loops with `Unlocking node keystore.. Permission denied`,
          # while `systemctl --failed` stays empty because a unit in
          # auto-restart reports `activating`.
          chown -R ${forgeUser}:${forgeUser} /var/lib/${forgeUser}

          # 0711 on the identity directory: TRAVERSABLE but not listable.
          # radicle-node reads the key as User=radicle inside the container and
          # this host's forge uid maps to container root, so a 0700 directory
          # blocks it at the PATH even when the file itself is readable -- a
          # failure indistinguishable from a bad file mode, since both are
          # `Permission denied` on the same open().
          install -d -m 0711 -o ${forgeUser} -g ${forgeUser} ${identityDir}

          SOPS_AGE_KEY_FILE=${identityDir}/age.key \
            sops --decrypt --extract '["radicle"]["node-key"]' \
            ${identityDir}/secrets.yaml > ${identityDir}/.node-key.new
          chown ${forgeUser}:${forgeUser} ${identityDir}/.node-key.new
          chmod 0444 ${identityDir}/.node-key.new
          mv -f ${identityDir}/.node-key.new ${identityDir}/node-key

          # Own by NAME on every start: the uid is allocated by NixOS and can
          # change, and files chowned to a stale number leave the role unable to
          # read its own identity -- surfacing as podman complaining about
          # .config rather than as anything naming the key.
          chown -R ${forgeUser}:${forgeUser} ${identityDir}
          chmod 0400 ${identityDir}/age.key ${identityDir}/secrets.yaml

          # 0444 for the same reason as the builder's: radicle-node reads its
          # keystore AFTER dropping to User=radicle inside the container, and
          # this host's forge uid maps to container ROOT, so a 0400 file owned
          # by it is unreadable to the one process that needs it. LoadCredential
          # is the upstream answer and cannot work here -- systemd builds the
          # credentials directory by mounting.
          #
          # What it widens is narrower here than on the builder: this container
          # runs no CI, so there is no repository-supplied shell inside to read
          # it. On the host nothing changes -- the directory is 0711 and owned
          # by an account nothing else uses.
          chmod 0444 ${identityDir}/node-key
          chmod 0711 ${identityDir}
        '';
      };
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.${name} = {
        # Streamed straight from the role -- no registry, no tarball in the
        # store.
        imageStream = role.config.system.build.image;
        # `localhost/` is not decoration: podman refuses an unqualified short
        # name, and defining a search registry for an image that is loaded
        # locally and must never be fetched would be the wrong fix.
        image = "localhost/${name}:${imageTag}";

        podman.user = forgeUser;

        volumes = [
          "${identityDir}:${identityDir}:ro"
          "${stateDir}/radicle:/var/lib/radicle"
          # The tailnet identity. NOT optional: oci-containers runs `podman rm
          # -f` in its pre-start, so the container is destroyed on every image
          # change -- and on nixos-unstable the image moves whenever the closure
          # does. Unpersisted, this seed would need re-authenticating by hand
          # after every rebuild, its tailnet name would drift to -1, -2, and the
          # externalAddresses above would quietly stop resolving to it.
          "${stateDir}/tailscale:/var/lib/tailscale"
        ];

        extraOptions = [
          # NET_ADMIN is not only for tailscaled: nixpkgs' firewall.service
          # carries ConditionCapability=CAP_NET_ADMIN, and systemd SKIPS a unit
          # whose condition is unmet rather than failing it -- so without this
          # the role comes up reporting `running`, with zero failed units and an
          # EMPTY ruleset. platforms/oci.nix's firewall-enforced unit turns that
          # silence into a failure.
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--device=/dev/net/tun"

          # systemd as PID 1 needs /run, /run/lock and the cgroup hierarchy as
          # tmpfs. podman does that in "systemd mode", which it auto-enables
          # ONLY when the command is literally /sbin/init, /usr/sbin/init,
          # /usr/local/sbin/init or systemd. A NixOS toplevel is a store path
          # ending in /init, which matches none of them -- so it must be forced.
          # Without it systemd execs and dies instantly, printing nothing, which
          # reads as an image problem and is not one.
          "--systemd=always"

          "--security-opt=no-new-privileges"
          # NO --userns=auto: it allocates a fresh uid range per container, so
          # the host uid owning the identity files is not mapped inside and the
          # read-only mount reads as an unmapped owner. Plain rootless podman
          # maps this host user to container root, which is what makes the mount
          # readable at all.

          # A seed serves rather than builds, so these are guard rails against a
          # runaway fetch rather than against hostile shell.
          "--pids-limit=2048"
          "--memory=4g"
          "--memory-swap=4g"
        ];
      };
    };
  };
}
