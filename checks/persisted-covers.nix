# A host's persisted directories for the user cover a path under ~, or the
# state there vanishes on reboot (/home is tmpfs). Fails in its build, never at
# evaluation (checks/fail-in-build.nix).
{ lib, runCommand }:
{ name, host, target, dirs }:
let
  covers = d: d == target || lib.hasPrefix "${lib.removeSuffix "/" d}/" target;
in
runCommand name { } ''
  ${lib.optionalString (!(lib.any covers dirs)) ''
    echo "FAIL  ${host} persists no directory of logger's covering ~/${target}"; exit 1
  ''}
  echo "PASS  persisted: ~/${target} is under a persisted directory of logger on ${host}" | tee "$out"
''
