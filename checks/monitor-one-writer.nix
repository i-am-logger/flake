# One writer per monitor rule (D1a, architect 2026-11-28): mynixos writes each
# monitor's hl.monitor (mode, vrr, bitdepth, cm hdr); vogix's display baseline
# stays empty on a mynixos host, so the daemon takes mynixos's rules as its
# baseline and vogix emits none. A second rule for the same monitor would lose
# HDR or make the baseline moot. Fails in its build, never at evaluation.
{ lib, runCommand }:
{ host, lua, output }:
let
  blocks = lib.filter (b: builtins.isString b && lib.hasInfix "[\"output\"] = \"${output}\"" b)
    (builtins.split "hl\\.monitor\\(" lua);
  n = lib.length blocks;
  b = if n == 1 then lib.head blocks else "";
  problems =
    lib.optional (n == 0) "no hl.monitor for ${output}"
    ++ lib.optional (n > 1) "${toString n} hl.monitor rules for ${output}: two writers"
    ++ lib.optional (n == 1 && !lib.hasInfix "[\"bitdepth\"] = 10" b) "the rule for ${output} lacks bitdepth 10"
    ++ lib.optional (n == 1 && !lib.hasInfix "[\"cm\"] = \"hdr\"" b) "the rule for ${output} lacks cm hdr"
    ++ lib.optional (n == 1 && !lib.hasInfix "[\"vrr\"]" b) "the rule for ${output} lacks vrr";
in
runCommand "monitor-one-writer-${host}" { } ''
  ${lib.concatMapStrings (p: ''
    echo ${lib.escapeShellArg "FAIL  ${host}: ${p}"}
  '') problems}
  ${lib.optionalString (problems != [ ]) "exit 1"}
  echo "PASS  monitor-one-writer: ${host} has one hl.monitor for ${output}, with bitdepth 10, cm hdr and vrr" | tee "$out"
''
