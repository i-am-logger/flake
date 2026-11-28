# Every Claude account's projects folder is a bind of ~/.claude/projects
# (decision 0209), from mynixos's accountProjects = "bind-mount" (row BM3):
# one mount per account, its prep oneshot ordered before every mount and
# required by it (so a boot never binds ~/.claude/projects onto itself), and
# home-manager waiting for the binds. Fails in its build, never at evaluation.
{ lib, runCommand }:
{ home, accounts, mounts, services, hmRequires }:
let
  src = "${home}/.claude/projects";
  dir = a: "${home}/.claude-${a}/projects";
  mountOf = a: lib.findFirst (m: m.where == dir a && m.what == src) null mounts;
  preps = m: map (lib.removeSuffix ".service") (lib.filter (lib.hasSuffix ".service") (m.requires or [ ]));
  ordered = m: lib.any (p: lib.length (services.${p}.before or [ ]) >= lib.length accounts) (preps m);
  problems = lib.concatMap
    (a:
      let m = mountOf a; in
      if m == null then [ "no bind of ~/.claude/projects at ~/.claude-${a}/projects" ]
      else lib.optional (!ordered m) "~/.claude-${a}/projects: its mount doesn't require a prep ordered before every bind"
        ++ lib.optional (!lib.elem (dir a) hmRequires) "~/.claude-${a}/projects: home-manager doesn't wait for it")
    accounts;
in
runCommand "claude-projects-binds" { } ''
  ${lib.concatMapStrings (p: ''
    echo ${lib.escapeShellArg "FAIL  ${p}"}
  '') problems}
  ${lib.optionalString (problems != [ ]) "exit 1"}
  echo "PASS  claude-projects-binds: ${toString (lib.length accounts)} accounts, each a bind of ~/.claude/projects, prep-ordered, home-manager waits" | tee "$out"
''
