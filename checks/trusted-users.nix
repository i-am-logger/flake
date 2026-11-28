# Nix's trusted users are root only: "Adding a user to trusted-users is
# essentially equivalent to giving that user root access to the system"
# (nix.conf(5)). @wheel counts, since the owner's account is in wheel (yoga
# security finding S2a; owner, 2026-11-28: "S3 + S2a + S9 now"). Fails in its
# build, never at evaluation.
{ lib, runCommand }:
{ host, trusted }:
let extra = lib.filter (u: u != "root") trusted; in
runCommand "trusted-users-${host}" { } ''
  ${lib.optionalString (extra != [ ]) ''
    echo ${lib.escapeShellArg "FAIL  ${host}: nix trusted-users includes ${lib.concatStringsSep ", " extra} (root-equivalent)"}; exit 1
  ''}
  echo "PASS  trusted-users: ${host} trusts root only" | tee "$out"
''
