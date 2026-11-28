# CLAUDE.md is loaded into every agent session whole, so it is held at exactly
# its byte budget (budgets.toml [docs] claude_md_bytes, at most 4096): over it
# fails, and so does under it, since a budget above the size measures nothing.
# The semantics are accountable's `check docs` (rust-pillars cf53423,
# crates/accountable-adapter/src/docs.rs), which needs a Cargo workspace.
# It fails in its own build, never at evaluation, so `nix flake check` still
# reports every other check.
{ runCommand }:
{ claudeMd, budgets }:
let
  ceiling = 4096;
  bytes = builtins.stringLength (builtins.readFile claudeMd);
  budget = (builtins.fromTOML (builtins.readFile budgets)).docs.claude_md_bytes;
in
runCommand "instructions-size" { } ''
  bytes=${toString bytes} budget=${toString budget} ceiling=${toString ceiling}
  if [ "$budget" -gt "$ceiling" ]; then
    echo "FAIL  budgets.toml claude_md_bytes is $budget, over the $ceiling ceiling (decision 0180)"; exit 1
  elif [ "$bytes" -gt "$budget" ]; then
    echo "FAIL  CLAUDE.md is $bytes bytes, over its budget of $budget: it is loaded into every session whole"; exit 1
  elif [ "$bytes" -lt "$budget" ]; then
    echo "FAIL  CLAUDE.md shrank to $bytes bytes, under its budget of $budget: lower [docs] claude_md_bytes to $bytes"; exit 1
  fi
  echo "PASS  instructions-size: CLAUDE.md is $bytes bytes, exactly its budget (<= $ceiling)" | tee "$out"
''
