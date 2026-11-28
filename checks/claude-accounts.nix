# Each expected Claude account is persisted as ~/.claude-<name>, and mynixos's
# own claudeAccounts step, run in a scratch home, links its four shared entries
# to ~/.claude. Fails in its build, never at evaluation.
{ lib, runCommand }:
{ expected, dirs, step }:
let
  unpersisted = lib.filter (a: !(lib.elem ".claude-${a}" dirs)) expected;
in
runCommand "claude-accounts" { } ''
  ${lib.optionalString (unpersisted != [ ]) ''
    echo "FAIL  ads-dev1 persists no ~/.claude-<name> for: ${lib.concatStringsSep " " unpersisted}"; exit 1
  ''}
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.claude"
  run() { "$@"; }
  ${step}
  fail=0
  for a in ${lib.escapeShellArgs expected}; do
    for n in projects sessions CLAUDE.md settings.json; do
      [ "$(readlink "$HOME/.claude-$a/$n")" = "$HOME/.claude/$n" ] \
        || { echo "FAIL  ~/.claude-$a/$n is not a link to ~/.claude/$n"; fail=1; }
    done
  done
  [ "$fail" = 0 ] || exit 1
  echo "PASS  claude-accounts: ${toString (lib.length expected)} accounts persisted, each with its 4 links" | tee "$out"
''
