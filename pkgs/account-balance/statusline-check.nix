# The status line and the balancer agree on usage-latest.json: runs the real
# statusLine command from a host's evaluated Claude settings on a sample stdin,
# then `account-balance usage` on the file it wrote, and asserts a numeric
# 5-hour % and an age of 0 minutes. A format drift between mynixos's recorder
# and the balancer (e.g. no saved_at, so every reading looks stale) fails here.
#
# hmConfig is the host's home-manager config for the user. mynixos embeds the
# merged settings as JSON in the claudeMergedSettings activation step, so the
# command is read from there: exactly what activation writes to settings.json.
{ lib
, runCommand
, jq
, gawk
, coreutils
, balancer
, hmConfig
}:

let
  # Each step is null when it is missing, so the check fails in its build with
  # the reason, never at evaluation (checks/fail-in-build.nix).
  step = hmConfig.home.activation.claudeMergedSettings.data or null;
  # `$_jq --argjson m '<json>' '. * $m'`, the JSON shell-quoted by escapeShellArg.
  quoted =
    if step == null then null
    else builtins.match "(.|\n)*--argjson m '(([^']|'\\\\'')*)' '\\. \\* \\$m'(.|\n)*" step;
  settings =
    if quoted == null then null
    else builtins.fromJSON (builtins.replaceStrings [ "'\\''" ] [ "'" ] (builtins.elemAt quoted 1));
  command = if settings == null then null else settings.statusLine.command or null;
  why =
    if step == null then "no claudeMergedSettings activation step: nothing merges Claude settings (usageRecord off?)"
    else if quoted == null then "claudeMergedSettings: merged settings JSON not found"
    else if command == null then "the merged Claude settings set no statusLine.command (usageRecord off?)"
    else null;
in
runCommand "account-balance-statusline"
{
  nativeBuildInputs = [ jq gawk coreutils ];
  # The activation package's closure holds the status-line script.
  activation = hmConfig.home.activationPackage or "";
  passthru = { inherit command settings; };
}
  ''
    ${lib.optionalString (why != null) ''
      echo ${lib.escapeShellArg "FAIL  ${why}"}; exit 1
    ''}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    unset CLAUDE_CONFIG_DIR
    now=$(date +%s)
    sample=$(jq -cn --argjson r "$((now + 3600))" --argjson w "$((now + 86400))" '{
      model: { display_name: "Claude" },
      rate_limits: {
        five_hour: { used_percentage: 42.5, resets_at: $r },
        seven_day: { used_percentage: 12, resets_at: $w }
      }
    }')

    fail=0
    check() { if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }

    line=$(printf '%s' "$sample" | ${toString command})
    check "statusline: prints a line" '[ -n "$line" ]'
    check "statusline: writes ~/.claude/usage-latest.json (default account)" \
      '[ -s "$HOME/.claude/usage-latest.json" ]'

    row=$(${balancer}/bin/account-balance usage 2>&1 | awk '$1 == "default"')
    echo "      usage row: ''${row:-<none>}"
    # usage: "<acct> <week%> <rate> <age-min> <5h%|-1>"
    pct=$(echo "$row" | awk '{print $5}')
    age=$(echo "$row" | awk '{print $4}')
    check "balancer: reads a numeric 5h% for default" \
      '[[ "$pct" =~ ^[0-9]+(\.[0-9]+)?$ ]]'
    check "balancer: the fresh reading has age 0 minutes" '[ "$age" = 0 ]'

    if [ "$fail" = 0 ]; then echo "RESULT: pass"; else echo "RESULT: FAIL"; fi
    [ "$fail" = 0 ] && echo pass >"$out"
  ''
