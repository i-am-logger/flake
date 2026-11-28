# Every check fails in its own build, never at evaluation: an evaluation error
# stops `nix flake check` before the other checks report, so one failure would
# hide the rest. Each case is a check given data that must fail it. The case
# must evaluate (tryEval), and its build must fail with a FAIL line
# (testers.testBuildFailure). This guard itself never throws.
{ lib, runCommand, testers }:
cases:
let
  evaluates = n: (builtins.tryEval (builtins.seq cases.${n}.drvPath true)).success;
  names = lib.attrNames cases;
  throwing = lib.filter (n: !(evaluates n)) names;
  building = lib.filter evaluates names;
  failed = lib.genAttrs building (n: testers.testBuildFailure cases.${n});
in
runCommand "checks-fail-in-build" { } ''
  fail=0
  ${lib.concatMapStrings (n: ''
    echo "FAIL  ${n}: throws at evaluation, which hides every other check's verdict"; fail=1
  '') throwing}
  ${lib.concatMapStrings (n: ''
    if grep -q '^FAIL  ' ${failed.${n}}/testBuildFailure.log; then
      echo "PASS  ${n}: evaluates, and its build fails with: $(grep -m1 '^FAIL  ' ${failed.${n}}/testBuildFailure.log | cut -c7-)"
    else
      echo "FAIL  ${n}: its build fails without a FAIL line"; fail=1
    fi
  '') building}
  [ "$fail" = 0 ] || exit 1
  echo "PASS  checks-fail-in-build: ${toString (lib.length names)} checks fail in their builds" | tee "$out"
''
