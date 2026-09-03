# The radicle CI BUILDER, as a machine.
#
# A SYSTEM, not part of any host, for the same reason as ./seed.nix: it has its
# own NID and its own tailnet node, and the host that runs it knows nothing else
# about it.
#
# BUILDERS ARE THE PLURAL ROLE THAT MATTERS. More of them is more CI lanes
# across repositories, and `lane` is what tells them apart -- "x64" is the
# architecture a lane builds natively, not the architecture of this file. yoga
# runs the x64 lane; skyspy-dev can run another the same way, and because
# streamLayeredImage shares layers, a second builder costs tens of megabytes
# rather than a second closure.
#
# ACCEPTED RISK, restated here because this is the file that turns CI on: the
# broker hands the decrypted node key to an adapter that runs
# repository-supplied shell, so a recipe can read this node's key. No delivery
# mechanism reaches that. It is acceptable because it is a BUILDER's key --
# disposable, and rotating it costs seconds -- and because `trustedNids` pins
# exactly whose pushes may start a run.
{ self }:

{
  # The host this instance runs on, present in the node name because a tailnet
  # name must be unique fleet-wide and tailscale silently appends -1 rather than
  # rejecting a collision.
  host

  # This node's radicle public key, WITHOUT a trailing comment. Disposable by
  # design: if a CI recipe walks off with the private half, mint another and the
  # fleet is unaffected. That property is the whole reason a builder does not
  # borrow a seed's key.
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

  # The architecture this lane builds natively.
  # Where the host mounts this node's identity. Passed in, not derived: the
  # path is baked into the ROLE and used by the HOST, and two derivations of
  # one path drift into a role looking for a key nothing mounted.
, identityDir

, lane ? "x64"

  # NIDs whose pushes and patches may trigger CI. MANDATORY, and asserted
  # non-empty by the domain: without a Node trigger filter, anyone who can reach
  # a seeded repository executes arbitrary code here.
, trustedNids ? [ "z6MkizPqxsNyqociVNMF4SnWCwDWFZ9udxkcejuagyR5CuZU" ] # logger@yoga

  # The repositories this builder runs CI for, named ONE BY ONE rather than
  # seeded by policy: every repository it seeds is one whose CI recipe it will
  # execute, and that should be a decision rather than a side effect of what
  # happens to be announced.
, seedRepositories ? [
    { rid = "rad:z2WxYCuLx8F8r2bPLPNjjboGM7qPU"; scope = "all"; } # secure-sweep-mobile
    { rid = "rad:z4KpNmJDpSD4xYHcsASaWa9y3AKTd"; scope = "all"; } # radicle-ci-smoke
  ]
}:

let
  name = "radicle-${host}-${lane}-builder";
in
self.lib.roles.radicle.builder {
  system = "x86_64-linux";
  inherit name lane publicKey connect trustedNids identityDir;

  my = [{
    system.ociImage.tag = host;
    infra.radicle.seedRepositories = seedRepositories;
  }];
}
