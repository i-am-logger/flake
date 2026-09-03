# A Radicle SEED, as a machine.
#
# An ordinary mynixos system, written exactly like systems/skyspy-dev: a
# hostname, and the services it enables. Nothing here knows it will be run as a
# container -- yoga decides that by putting it in `my.virtualisation.containers`,
# and could equally build it as a VM or install it on metal.
#
# SEEDS ARE PLURAL BY DESIGN. Radicle gives every seed its own NID, which lives
# in the key rather than the address, so a second seed stands up ALONGSIDE a
# running one and neither cutover nor rollback exists: both are entries in every
# workstation's `connect` list until one is removed.
{ mynixos

  # The host whose fleet this seed belongs to. Present in the name because a
  # tailnet name must be unique FLEET-wide and tailscale does not reject a
  # collision -- it silently appends -1, leaving two hosts' seeds
  # indistinguishable in the one place you would look to tell them apart.
, host

  # This node's radicle public key, WITHOUT a trailing comment. Public data; the
  # private half arrives at runtime already decrypted, from whatever runs this.
  #
  # NOT disposable, unlike a builder's: every workstation pins this NID in a
  # `connect` entry, so rotating it means visiting each of them.
, publicKey

  # Where the runner mounts this node's identity. Passed in rather than derived:
  # the path is used by the machine AND by whatever hosts it, and two
  # derivations of one path drift into a node looking for a key nothing mounted.
, identityDir ? "/var/lib/radicle-identity"

  # `<nid>@<host>:<port>` peers this seed dials. Empty for the only seed on a
  # fleet; when a second exists each lists the other, so the pair re-forms
  # whichever restarts.
, connect ? [ ]

  # Where CI reports are read from. A seed serves the explorer, but CI runs on a
  # BUILDER and the reports exist only there -- so this is a window onto another
  # machine, not a local directory.
, ciReportsFrom ? null

, avatarDefault ? null
, avatarsByEmail ? { }
, tailnet ? "tail46cce1.ts.net"
, ...
}:

let
  name = "radicle-${host}-seed";
  tailnetName = "${name}.${tailnet}";

  # Two independent optional attrs, bound SEPARATELY. Nesting one inside the
  # other made avatars depend on ciReports, so a seed with avatars and no
  # reports silently lost them.
  ciReportsAttrs =
    if ciReportsFrom == null then { } else { ciReports.proxyTo = ciReportsFrom; };

  avatarAttrs =
    if avatarDefault == null then { } else {
      avatars = { default = avatarDefault; byEmail = avatarsByEmail; };
    };
in
mynixos.lib.mkSystem {
  # No hardware profile to derive an architecture from, so it is named.
  system = "x86_64-linux";

  my = [{
    system.hostname = name;

    # Its own tailnet node. Tagged, because an OAuth-registered node must be and
    # because a tagged node's key never expires -- a seed that silently drops
    # off the tailnet is a seed that stops replicating.
    network.tailscale = {
      enable = true;
      tags = [ "tag:radicle-seed" ];
    };

    infra.radicle = {
      enable = true;
      seed.enable = true;
      inherit publicKey;

      # The private half is already decrypted where this points, so no sops
      # secret is declared at all: sops-install-secrets runs whenever ANY secret
      # exists, and it mounts a ramfs, which needs a CAP_SYS_ADMIN this machine
      # may not have when it runs as a container.
      privateKeyFile = "${identityDir}/node-key";

      node = {
        inherit connect;
        # What peers dial. A seed is DIALED and must advertise a name they can
        # resolve, which is the tailnet name and never localhost.
        externalAddresses = [ "${tailnetName}:8776" ];
      };

      httpd.explorer = {
        # Fetched by the BROWSER, so it must be a name the browser resolves.
        seedHostname = tailnetName;
        # https, so the page is a secure context; tailscale serve terminates TLS
        # with the tailnet's own certificate.
        scheme = "https";
        externalPort = 443;
      } // ciReportsAttrs // avatarAttrs;
    };
  }];
}
