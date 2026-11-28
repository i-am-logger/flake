# The C9 check: account-balance against a stub herdr (test/herdr-stub.sh) and
# fixture usage files (test/check.sh). The balancer is built with the stub AS
# its herdr, so the real one is never on its PATH.
{ callPackage
, writeShellApplication
, runCommand
, jq
, coreutils
, procps
, util-linux
, gnugrep
, gawk
, tzdata
}:

let
  herdrStub = writeShellApplication {
    name = "herdr";
    runtimeInputs = [ jq coreutils ];
    text = builtins.readFile ./test/herdr-stub.sh;
  };
  balancer = callPackage ./. { herdr = herdrStub; };
in
runCommand "account-balance-check"
{
  nativeBuildInputs = [ herdrStub jq coreutils procps util-linux gnugrep gawk tzdata ];
  passthru = { inherit balancer herdrStub; };
}
  ''
    rc=0
    export TZDIR=${tzdata}/share/zoneinfo
    BALANCE=${balancer}/bin/account-balance WORK="$TMPDIR/work" \
      bash ${./test/check.sh} >"$TMPDIR/check.log" 2>&1 || rc=$?
    cat "$TMPDIR/check.log"
    # The output holds only the named results, so it is the same on every run;
    # the full log (with timestamps) stays in the build log.
    grep -E '^(PASS|FAIL|RESULT)' "$TMPDIR/check.log" >"$out" || true
    exit "$rc"
  ''
