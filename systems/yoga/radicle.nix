# Radicle forge layer for yoga — the fleet's seed, CI and GitHub-mirror host.
# Full design and runbook: mynixos docs/radicle.md.
#
# BOOTSTRAP GATE. Everything below is inert until `infra.radicle.enable` flips
# to true, and flipping it needs the key material only a human can mint:
#
#   1. Seed machine key (offline, never against the real /var/lib/radicle):
#        export RAD_HOME=$(mktemp -d) RAD_PASSPHRASE=
#        rad auth --alias seed-yoga
#        rad self --nid                 # -> seedNid below, and every connect list
#        cat $RAD_HOME/keys/radicle.pub # -> publicKey below (STRIP the comment)
#      Private key file content -> ~/.secrets/secrets.yaml under radicle/node-key,
#      then rm -rf $RAD_HOME.
#   2. Personal identity on each machine (passphrase-less; the disks are
#      encrypted): rad auth, then `rad self --nid`. Your own machines' NIDs
#      fill ci.trustedNids and mirror.sourceNid. The SEED's NID from step 1 --
#      not these -- is what the per-user node.connect in users/logger (linux
#      tier) points at.
#   3. GitHub fine-grained PAT (Contents: RW on exactly the mirrored repos)
#      -> secrets.yaml under radicle/github-token. Mirror repos are added
#      per-RID after `rad init`.
#   4. Darwin builder key: ssh-keygen -t ed25519 -N "" -f builder_ed25519;
#      private half -> secrets.yaml under nix/remote-builder-key; public half
#      -> my.dev.builderHost.authorizedKey on aether5d-dev. Then uncomment
#      dev.remoteBuilders below (declaring it earlier would make sops fail
#      activation on the missing secret).
#
# FLIP IN THREE STAGES, not one — the module asserts that each role has its
# inputs, so turning everything on at once fails the build by design:
#   A. after step 1: infra.radicle.enable = true (node + httpd only).
#      Verify, then run the no-egress proof from docs/radicle.md.
#   B. after step 2: fill ci.trustedNids, then ci.enable = true
#      (asserted non-empty: an empty filter would let anyone's patch run
#      shell on this host).
#   C. after step 3 AND a first `rad init`: fill mirror.sourceNid and at
#      least one mirror.repos entry, then mirror.enable = true
#      (asserted non-empty — there are no RIDs to mirror before rad init).
# Step 4 (the darwin builder) is independent and can land any time after A.
{
  infra.radicle = {
    enable = true; # GATE A OPEN — node + httpd (seed key minted 2026-08-31)

    # Minted 2026-08-31 (offline, temp RAD_HOME, shredded). Comment stripped,
    # as services.radicle requires. NID: z6MkqSoohjxUYVfQRqFxCKeRGSJeE8D5dTxkBe8neHWt6Rb1
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNS4xxQKGXWZ78kgQchx4K1937BhcrevMBZv8BK2DKs";

    node = {
      # Advertised inside the tailnet only; workstations still dial by their
      # own static connect lists.
      externalAddresses = [ "yoga.tail46cce1.ts.net:8776" ];
      # The fleet seed carries everything ours; workstations keep the
      # default "block".
      defaultSeedingPolicy = "allow";
    };

    # The API (8780) plus the browsable explorer UI (8781), both tailnet-only.
    # httpd alone answers JSON on every path -- the explorer is the actual
    # forge you can read, served from this host so no third-party JavaScript
    # ever touches the repositories.
    httpd = {
      enable = true;
      explorer = {
        enable = true;
        # Baked into the SPA and fetched by the BROWSER, so it must be a name
        # the browser resolves -- the MagicDNS name, not localhost.
        seedHostname = "yoga.tail46cce1.ts.net";
        # Served through `tailscale serve`, which terminates TLS with the
        # tailnet's own certificate -- so https://yoga.tail46cce1.ts.net/ is a
        # real secure context rather than a browser warning. Same mechanism
        # already used for the praxis dev server on 1989.
        scheme = "https";
        externalPort = 443;
        # The explorer builds gravatar.com URLs from committer emails; the
        # module rewrites that to this host so the browser never calls out.
        # Keyed on the address that appears in COMMITS.
        avatars = {
          default = ../../users/logger/avatar.png;
          byEmail."i-am-logger@users.noreply.github.com" = ../../users/logger/avatar.png;
        };
      };
    };

    ci = {
      enable = true; # GATE B OPEN — trustedNids filled below
      # The Android toolchain deliberately does NOT live in mynixos, and not
      # in this host config either: it is defined by the repo being built
      # (SecureSweep/devenv.nix pins SDK 35/36, NDK 26.1.10909125 to match
      # build.gradle.kts, JDK 25). All the builder needs is devenv itself --
      # the toolchain is then realised into the nix store once and reused by
      # every later run, rather than installed per build.
      adapters.native.extraRuntimePackages = [ pkgs.devenv ];

      trustedNids = [
        # Personal machine NIDs ONLY — a listed NID's pushes execute
        # repo-supplied shell on this host. Add skyspy-dev's after `rad auth`
        # there; the Mac has no node, so it never needs an entry.
        "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU" # logger@yoga
      ];
    };

    mirror = {
      enable = false; # GATE C — needs sourceNid + at least one repo below
      # Whose signed view is mirrored: storage keeps only the canonical
      # default branch at top level, so the delegate namespace is the only
      # view carrying every branch and tag.
      sourceNid = "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU"; # logger@yoga
      repos = [
        # One entry per public projection, added as repos are rad-init'ed:
        # { rid = "rad:z…"; githubRepo = "i-am-logger/<repo>";
        #   releases = { enable = true;
        #                systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]; }; }
      ];
    };
  };

  # TODO(runbook 4): uncomment once nix/remote-builder-key exists in sops —
  # the aarch64-darwin leg of CI and releases. hostName and the pinned host
  # key are real (captured 2026-08-31); only the secret is missing.
  # dev.remoteBuilders = [{
  #   hostName = "aether5d-dev.tail46cce1.ts.net";
  #   systems = [ "aarch64-darwin" ];
  #   publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUk3Szh2eGsreldlNnM3SitRV3FVTkFYUHFoRFFnTHBNTWhxQ0l3dkhtQ00=";
  # }];
}
