# vogix reaches the hosts through flake's own `vogix` input, which mynixos's
# vogix input follows (owner, 2026-11-28: no mynixos edits for vogix v1).
# hosts: name -> { vogix = <programs.vogix.enable>; drvPath = <toplevel drvPath>; }
# Fails in its build, never at evaluation.
{ lib, runCommand }:
{ own, follows, mynixosVogix, hosts }:
let
  ownPath = if own == null then null else own.outPath;
  problems =
    lib.optional (own == null) "flake declares no vogix input"
    ++ lib.optional (follows != [ "vogix" ])
      "mynixos's vogix input does not follow flake's (lock: ${builtins.toJSON follows})"
    ++ lib.optional (own != null && mynixosVogix != ownPath)
      "mynixos's vogix (${toString mynixosVogix}) is not flake's (${toString ownPath})"
    ++ lib.concatLists (lib.mapAttrsToList (h: v: lib.optional (!v.vogix) "${h} does not enable vogix") hosts);
  evaluated = lib.concatStringsSep ", " (lib.mapAttrsToList (h: v: builtins.seq v.drvPath h) hosts);
in
runCommand "vogix-v1-host" { } ''
  ${lib.concatMapStrings (m: ''
    echo ${lib.escapeShellArg "FAIL  ${m}"}
  '') problems}
  ${lib.optionalString (problems != [ ]) "exit 1"}
  echo "PASS  vogix: mynixos's vogix follows flake's (${if own == null then "?" else own.rev or "?"}); ${evaluated} enable it and evaluate" | tee "$out"
''
