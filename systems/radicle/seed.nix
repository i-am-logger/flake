# The radicle SEED, as a machine.
#
# A SYSTEM, not part of any host. A host builds this and runs it as a container;
# it has its own NID, its own tailnet node and its own storage, and knows
# nothing about the machine underneath it. That is why this file sits beside
# yoga rather than inside it.
#
# PARAMETERISED BY HOST so any host can run one. yoga runs the fleet's seed
# today; skyspy-dev can run a second the same way, and a second seed is a normal
# fleet member rather than a migration -- radicle's replication model makes
# seeds plural because a node's identity is its NID and the NID lives in the
# KEY, not the address.
#
# WHICH IS WHY EACH NODE NEEDS ITS OWN KEY, and why this file takes one rather
# than holding one: two nodes sharing a key would both sign the same sigrefs,
# and Noise XK pins the responder key, so a client dialling that NID could land
# on either and fail the handshake. Minting a seed key is a deliberate act with
# a real cost -- every workstation pins the NID in a `connect` entry, so
# rotating it means visiting each of them.
{ self, tailnet ? "tail46cce1.ts.net" }:

{
  # The host this instance will run on. Present in the node name because a
  # tailnet name must be unique FLEET-wide, and tailscale does not reject a
  # collision -- it silently appends -1, leaving two hosts' seeds
  # indistinguishable in the one place you would look to tell them apart.
  host

  # This node's radicle public key, as `keys/radicle.pub` holds it and WITHOUT
  # a trailing comment. Public data; the private half arrives at runtime,
  # already decrypted, from the host that runs it.
, publicKey

  # Peers this seed dials. A seed is DIALED -- by workstations and by builders
  # -- so this is empty for the only seed on a fleet. When a second exists, each
  # lists the other here so the pair re-forms whichever restarts.
, connect ? [ ]

  # Repositories the fleet's seeds carry. `defaultSeedingPolicy = "allow"` (set
  # by the role) accepts what is ANNOUNCED, and an announcement happens on push
  # -- so repositories that already existed when a seed was created would never
  # be re-announced, and the seed would look healthy while holding nothing.
  # Naming them is what makes a new node fetch them.
, seedRepositories ? [
    { rid = "rad:z2WxYCuLx8F8r2bPLPNjjboGM7qPU"; scope = "all"; } # secure-sweep-mobile
    { rid = "rad:z4KpNmJDpSD4xYHcsASaWa9y3AKTd"; scope = "all"; } # radicle-ci-smoke
  ]

  # Where CI reports are proxied from. They exist only on the builder that
  # produced them, so whatever fronts the forge UI proxies to it rather than
  # reading its filesystem across a userns boundary.
, ciReportsFrom ? null

  # WHERE THE HOST WILL MOUNT THIS NODE'S IDENTITY. Passed in rather than
  # derived here, because the path is baked into the ROLE (the node reads its
  # key from it) AND used by the host (which bind-mounts it). Two derivations of
  # one path drift: an earlier version computed it here and let the host declare
  # its own, so the role looked for a key at a path nothing mounted and exited
  # 243/CREDENTIALS -- a container that starts and is never identified.
, identityDir

, avatarDefault ? null
, avatarsByEmail ? { }
}:

let
  name = "radicle-${host}-seed";
  tailnetName = "${name}.${tailnet}";

  # Two INDEPENDENT optional pieces of the explorer, bound separately and merged
  # side by side below. Nesting one inside the other -- which is what writing
  # them as chained `//` conditionals produces -- silently makes the second
  # depend on the first, so a seed with no CI proxy would also lose its avatars
  # and start calling gravatar.com again.
  ciReportsAttrs =
    # Only when the host names one. A DEFAULT would be wrong: every seed would
    # proxy CI reports from whichever builder happened to be written into this
    # file, so a seed on another host would serve another machine's reports as
    # its own.
    if ciReportsFrom == null then { } else { ciReports.proxyTo = ciReportsFrom; };

  avatarAttrs =
    # NOT decoration. Without avatars the explorer bundle calls
    # www.gravatar.com with an md5 of every committer's address; the module
    # rewrites that host to a same-origin /avatars/ path only when they are
    # enabled. Leaving them off would have a tailnet-private forge announce who
    # commits to it to a third party on every page view.
    if avatarDefault == null then { } else {
      avatars = { default = avatarDefault; byEmail = avatarsByEmail; };
    };
in
self.lib.roles.radicle.seed {
  system = "x86_64-linux";
  inherit name publicKey connect identityDir;

  # A seed is DIALED, so unlike a builder it must advertise where. Its OWN
  # tailnet name, never the host's: an address is not an identity here, and
  # putting a seed behind a host name is what a per-key NID makes meaningless.
  externalAddresses = [ "${tailnetName}:8776" ];

  # Baked into the explorer SPA at build time and fetched by the BROWSER, so it
  # has to be a name the browser resolves -- this container's tailnet name,
  # never "localhost" and never the host's.
  seedHostname = tailnetName;


  my = [
    {
      # Distinguishes THIS deployment's image from another host's image of the
      # same role. The default is "reference", which marks mynixos' own
      # reference fleet -- images built for keys whose private halves were
      # destroyed, and which must never be mistaken for a deployment.
      system.ociImage.tag = host;

      infra.radicle = {
        inherit seedRepositories;

        # No CI here. CI runs on a builder, which is the only machine its
        # reports exist on; a seed that also built would put
        # repository-supplied shell next to a key that is expensive to rotate.
        #
        # The optional avatars merge at THIS level, beside their siblings.
        # Merging one level higher looks equivalent and is not: `//` is
        # SHALLOW, so a second `infra` would REPLACE the first outright and
        # scheme, externalPort and ciReports would vanish. That silently
        # reverted the explorer to plain http with no CI proxy, and nothing
        # caught it except the role's image derivation changing.
        httpd.explorer = {
          # HTTPS without running a CA or an ACME client: tailscaled already
          # holds a certificate for this container's own tailnet name, and
          # `serve` terminates TLS with it and proxies to nginx on loopback.
          # Under https the role's nginx binds LOOPBACK ONLY, so `serve` is the
          # single front door rather than a second, unencrypted way in.
          scheme = "https";
          externalPort = 443;
        } // ciReportsAttrs // avatarAttrs;
      };
    }
  ];
}
