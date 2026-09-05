# A Radicle CI BUILDER, as a machine.
#
# An ordinary mynixos system. What makes it a builder is one switch --
# `infra.radicle.builder.enable` -- and everything that follows from it (seeding
# policy, the broker, report serving) is the service's business, in mynixos.
#
# BUILDERS ARE THE PLURAL ROLE THAT MATTERS: more of them is more CI lanes, and
# each is its own tailnet node with its own radicle identity. `lane` is what
# tells them apart -- "x64" is the architecture a lane builds natively, not the
# architecture of this file.
#
# ACCEPTED RISK, restated here because this is the file that turns CI on: the
# broker hands the decrypted node key to an adapter that runs
# repository-supplied shell, so a recipe can read this node's key. No delivery
# mechanism reaches that. It is acceptable because a builder's key is DISPOSABLE
# -- mint another and the fleet is unaffected -- and because `trustedNids` pins
# exactly whose pushes may start a run. That property is the whole reason a
# builder does not share a machine, an account or a key with a seed.
{ mynixos
, host
, publicKey

  # The seed this builder dials, as `<nid>@<host>:<port>`. A builder DIALS OUT
  # and is never dialed, so it advertises nothing and needs no inbound
  # reachability at all.
  #
  # Expensive to get wrong: the broker watches its OWN node's event stream, so a
  # builder with no reachable seed fetches nothing, sees no announcements and
  # never triggers a build -- sitting there `active`, with no failed unit and an
  # empty CI history, indistinguishable from nobody having pushed.
, connect

  # Where a reader reaches this builder's CI reports. Cannot be derived here:
  # this machine is fronted by whatever runs it, and knows neither that host's
  # name nor the path it is mounted under. Unset, the adapter has no `base_url`,
  # which upstream calls "mandatory for access from CI broker page" -- every run
  # then renders as the bare word "failure" with no link to its log.
, reportsPublicUrl ? null

, identityDir ? "/var/lib/radicle-identity"
, lane ? "x64"

  # NIDs whose pushes and patches may trigger CI. Without a Node trigger filter,
  # anyone who can reach a seeded repository executes arbitrary code here.
, trustedNids ? [ "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU" ] # logger@yoga

  # The fleet's repositories, from ../radicle/repositories.nix. A builder seeds
  # the ones marked `ci`, and ONLY those: every repository it seeds is one whose
  # CI recipe it will execute, so that has to be a decision rather than a side
  # effect of what happens to be announced.
, repositories ? import ../radicle/repositories.nix
, ...
}:

let
  # scope = "all" because the point is to build what OTHER peers push, not only
  # what this node follows.
  ciRepositories = builtins.map
    (r: { inherit (r) rid; scope = "all"; })
    (builtins.filter (r: r.ci) (builtins.attrValues repositories));
in
mynixos.lib.mkSystem {
  system = "x86_64-linux";

  my = [{
    system.hostname = "radicle-${host}-${lane}-builder";

    # Tag the builders: reach on a tailnet is entirely ACL policy, and an
    # untagged builder can otherwise reach every other node.
    network.tailscale = {
      enable = true;
      tags = [ "tag:radicle-builder" ];

      # WHAT THIS BUILDER MUST BE ABLE TO REACH for its liveness probe to pass.
      #
      # The SEED is deliberately not named here. my/infra/radicle derives it
      # from `connect`, so the peer whose reachability is the point cannot drift
      # from the peer this builder actually dials -- and getting that wrong is
      # the failure described at the top of this file.
      #
      # What is added is the fleet host, and it is what splits two questions a
      # single peer conflates. Nothing answering means this node is off the
      # tailnet: a restart is a plausible repair, so the container exits. The
      # seed alone staying silent means the node is fine and someone else is
      # down, which no restart of this machine can fix -- so it fails the probe
      # unit and stays visible in `systemctl --failed` instead of rebooting a
      # builder mid-job every few minutes for the duration of a seed outage.
      liveness.peers = [ host ];
    };

    infra.radicle = {
      enable = true;
      builder.enable = true;
      inherit publicKey;
      privateKeyFile = "${identityDir}/node-key";

      node = { inherit connect; };
      seedRepositories = ciRepositories;

      ci = {
        inherit trustedNids;
        serveReports.publicUrl = reportsPublicUrl;
      };
    };
  }];
}
