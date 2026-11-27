#!/usr/bin/env bash
# account-balance: move idle Claude sessions off accounts near their 5-hour or weekly limit.
#
#   account-balance status                         every Claude pane: account, herdr status, verdict
#   account-balance plan  [--max N]                the moves an apply run would make now (changes nothing)
#   account-balance apply [--max N]                make those moves, one at a time
#   account-balance move <session>/<pane> <acct>   move one pane (same safety checks)
#   account-balance restart <session>/<pane>       restart one pane on its own account (reloads settings)
#   account-balance usage | weekly                 the usage readings of the pool members
#   account-balance pause <set_by> <hours> <reason> | unpause
#
# Config is data written by the flake (ACCOUNT_BALANCE_CONFIG, JSON): pools of accounts, thresholds, and the
# held herdr sessions. An account is `default` (~/.claude, CLAUDE_CONFIG_DIR unset) or a name N (~/.claude-N).
# Usage is read from <folder>/usage-latest.json of each pool member BY NAME, never by a glob. Moves stay
# inside one pool, and only pool members are sources or targets.
#
# Panes are keyed <session>/<pane> everywhere (pane ids repeat across herdr sessions): plan rows, moves.log,
# resume-ids.log, skip.txt (<session>/<name>) and the per-target counts. Session names come only from
# `herdr session list --json` rows with running=true (`herdr --session <name>` creates a missing session), and
# every other herdr call passes --session. Panes in a held session are reported by status, never planned or
# moved.
#
# A session is moved only when ALL hold, checked twice (at plan time and again right before /exit):
#   - herdr agent_status is idle or done, and the visible pane has no "esc to interrupt", dialog or draft;
#   - the claude process has no child processes (this is also what keeps a session out mid-gate: cops/releasable
#     gates run as children of the session that started them, with no systemd scope of their own to detect);
#   - <session>/<name> is not in the skip list (skip.txt in the state folder, one per line);
#   - the target account has accepted the workspace-trust dialog for the session's folder.
# Sources: members at >= high % of the 5-hour limit, or >= week_high % weekly. Targets: members below low %
# with a fresh (<= stale_min minutes) reading and under week_low % weekly, lowest use first; at most
# per_target moves land on one account per run. Any failed move stops the run (circuit breaker); a move whose
# new session does not come up is resumed again on its original account.
#
# One lock (balance.lock in the state folder) is held for the whole of apply, move and restart: apply skips
# when it is taken, a manual move or restart waits up to 600 s for it.
set -uo pipefail

config=${ACCOUNT_BALANCE_CONFIG:?ACCOUNT_BALANCE_CONFIG must name the JSON config}
cfg() { jq -r "$1" "$config"; }
HIGH=$(cfg .thresholds.high) LOW=$(cfg .thresholds.low) PER_TARGET=$(cfg .thresholds.per_target)
WEEK_HIGH=$(cfg .thresholds.week_high) WEEK_LOW=$(cfg .thresholds.week_low)
STALE_MIN=$(cfg .thresholds.stale_min) MAX=$(cfg .thresholds.max)

state_dir=${ACCOUNT_BALANCE_STATE:-$HOME/.local/state/account-balance}
log_file=$state_dir/moves.log
skip_file=$state_dir/skip.txt
lock_file=$state_dir/balance.lock
mkdir -p "$state_dir"

# every pool member, one per line; the members of one pool; the pool of an account (empty when none)
members() { cfg '.pools[][]'; }
pool_members() { jq -r --arg p "$1" '.pools[$p][]' "$config"; }
pool_of() { jq -r --arg a "$1" '.pools | to_entries[] | select(.value | index($a) != null) | .key' "$config" | head -1; }
held() { jq -e --arg s "$1" '.held_sessions | index($s) != null' "$config" >/dev/null; }

# Running herdr sessions, the only source of session names (C4).
sessions() { herdr session list --json </dev/null 2>/dev/null 9>&- | jq -r '.sessions[]? | select(.running == true) | .name'; }
# hs <session> <herdr args...>: every herdr call but the session list goes through here. stdin is closed (the
# callers read loops from it) and so is the lock's fd 9, so nothing herdr starts can hold the lock.
hs() { local s=$1; shift; herdr --session "$s" "$@" </dev/null 9>&-; }

cfgdir() { [ "$1" = default ] && echo "$HOME/.claude" || echo "$HOME/.claude-$1"; }
acct_of_dir() { case ${1%/} in "$HOME/.claude"|"") echo default ;; *) echo "${1##*/.claude-}" ;; esac; }
# The launch prefix for an account. `default` means NO CLAUDE_CONFIG_DIR: setting it to ~/.claude makes Claude
# read ~/.claude/.claude.json instead of ~/.claude.json.
launch_env() { [ "$1" = default ] && echo "env -u CLAUDE_CONFIG_DIR" || echo "CLAUDE_CONFIG_DIR=$(cfgdir "$1")"; }
cfgjson() { [ "$1" = default ] && echo "$HOME/.claude.json" || echo "$(cfgdir "$1")/.claude.json"; }
# trusted <pid> <acct>: the account has already accepted the workspace-trust dialog for the session's cwd or
# a folder above it (trust is inherited); moving a session to an account that hasn't stops it at that dialog.
trusted() {
  local cwd; cwd=$(readlink "/proc/$1/cwd" 2>/dev/null) || return 1
  jq -e --arg c "$cwd" '[.projects // {} | to_entries[] | select(.value.hasTrustDialogAccepted == true) | .key
      | select(. as $k | $c == $k or ($c | startswith(($k | rtrimstr("/")) + "/")))] | length > 0' \
    "$(cfgjson "$2")" >/dev/null 2>&1
}

# usage: "<acct> <5h%> <age-min> <saved_at> <resets_at>" per pool member with a reading
usage() {
  local now a f; now=$(date +%s)
  while read -r a; do
    f=$(cfgdir "$a")/usage-latest.json; [ -r "$f" ] || continue
    jq -r --arg a "$a" --argjson now "$now" \
      '"\($a) \(.rate_limits.five_hour.used_percentage // -1) \((($now - (.saved_at // 0)) / 60) | floor) \(.saved_at // 0 | floor) \(.rate_limits.five_hour.resets_at // 0 | floor)"' "$f"
  done < <(members)
}

# "<acct> <seven_day %>" per pool member; -1 when the file has no seven_day reading
weekly() {
  local a f
  while read -r a; do
    f=$(cfgdir "$a")/usage-latest.json; [ -r "$f" ] || continue
    jq -r --arg a "$a" '"\($a) \(.rate_limits.seven_day.used_percentage // -1 | floor)"' "$f"
  done < <(members)
}

pane_pid() { hs "$1" pane process-info --pane "$2" 2>/dev/null |
  jq -r '.result.process_info.foreground_processes[]? | select(.argv[0] == "claude") | .pid' | head -1; }

# "<session>/<pane> <name> <status> <pid> <acct>" for every pane running claude, in every running session
panes() {
  local s id name st pid dir
  while read -r s; do
    [ -n "$s" ] || continue
    hs "$s" pane list 2>/dev/null | jq -r '.result.panes[]? | select(.agent == "claude") |
      "\(.pane_id) \((.terminal_title_stripped // "") | if . == "" then "?" else gsub(" "; "%20") end) \(.agent_status)"' |
    while read -r id name st; do
      pid=$(pane_pid "$s" "$id"); [ -n "$pid" ] || continue
      dir=$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | sed -n 's/^CLAUDE_CONFIG_DIR=//p')
      echo "$s/$id $name $st $pid $(acct_of_dir "$dir")"
    done
  done < <(sessions)
}

# verdict <session>/<pane> <name> <status> <pid>: prints "ok" or the reason the pane must not be moved now
verdict() {
  local key=$1 name=$2 st=$3 pid=$4 s id
  s=${key%%/*} id=${key#*/}
  held "$s" && { echo held; return; }
  [[ $name == acct-* ]] && { echo account-pinned; return; }
  [ "$name" = "?" ] && { echo no-title; return; }
  [[ $name == *%20* ]] && { echo name-has-spaces; return; }
  # ALLOW_SKIP=1 is for a manual `move` only, when the skip-listed session itself asked to be moved.
  [ -f "$skip_file" ] && grep -qxF "$s/$name" "$skip_file" && [ "${ALLOW_SKIP:-0}" != 1 ] && { echo skip-list; return; }
  case $st in idle|done) ;; *) echo "status=$st"; return ;; esac
  hs "$s" pane read "$id" --source visible --lines 40 2>/dev/null | grep -q 'esc to interrupt' && { echo busy-spinner; return; }
  # Screen check until a typed "pane is at a dialog / has a draft" source exists (herdr reports "done" for both):
  # an open dialog or text already in the input box would receive the /exit keystrokes and Enter.
  local scr; scr=$(hs "$s" pane read "$id" --source visible --lines 12 2>/dev/null)
  grep -qE 'Enter to [a-z].*Esc to |Esc to cancel|Do you want to' <<<"$scr" && { echo dialog-open; return; }
  # Unsent feedback drafts (status bar "· N feedback draft(s)"): /exit would open the drafts dialog, where Esc
  # DISCARDS them, and the session would sit frozen in it.
  local fb; fb=$(grep -oE '· [0-9]+ feedback drafts?' <<<"$scr" | tail -1 | grep -oE '[0-9]+')
  [ -n "$fb" ] && { echo "feedback-drafts($fb)"; return; }
  # The input line is read with its styling: Claude Code draws its prompt SUGGESTION dim (ESC[2m), which is not a
  # draft. Dim segments are dropped before checking.
  local inp; inp=$(hs "$s" pane read "$id" --source visible --lines 12 --format ansi 2>/dev/null | grep '❯' | tail -1 |
    sed -E $'s/\e\\[2m[^\e]*//g; s/\e\\[[0-9;]*m//g; s/\r//g')
  grep -qE '❯ +[^ ]' <<<"$inp" && { echo input-has-text; return; }
  # ALLOW_CHILDREN=1 is for a manual `move` only, after reading what the children are: they end with the session.
  [ -n "$(pgrep -P "$pid")" ] && [ "${ALLOW_CHILDREN:-0}" != 1 ] && { echo "has-children($(pgrep -P "$pid" | wc -l))"; return; }
  echo ok
}

status() {
  local u key name st pid a; u=$(usage)
  echo "accounts (acct 5h% age-min saved_at resets_at):"; echo "$u" | sort -k2 -n | sed 's/^/  /'
  echo "sessions (session/pane name status pid acct verdict):"
  panes | while read -r key name st pid a; do echo "  $key $name $st $pid $a $(verdict "$key" "$name" "$st" "$pid")"; done
}

# prints "<session>/<pane> <name> <from> <to>" lines
plan() {
  local u w p pool m hot targets n=0 key name st pid a t c pct
  declare -A load=()
  u=$(usage); w=$(weekly); p=$(panes)
  while read -r pool; do
    m=" $(pool_members "$pool" | tr '\n' ' ')"
    [ "$m" != " " ] || continue
    hot=$( { awk -v m="$m" -v h="$HIGH" 'index(m, " " $1 " ") && $2 >= h { print $1 }' <<<"$u"
             awk -v m="$m" -v h="$WEEK_HIGH" 'index(m, " " $1 " ") && $2 >= h { print $1 }' <<<"$w"; } | sort -u)
    [ -n "$hot" ] || continue
    # lowest 5h% first; stale usage (> stale_min minutes) is not trusted; never an account at >= week_low weekly
    # or with no weekly reading. A 5h of -1 (no five_hour reading: no window open) counts as 0.
    targets=$(awk -v m="$m" -v l="$LOW" -v wl="$WEEK_LOW" -v sm="$STALE_MIN" 'NR == FNR { wk[$1] = $2; next }
        index(m, " " $1 " ") && $2 < l && $3 <= sm && ($1 in wk) && wk[$1] >= 0 && wk[$1] < wl {
        print ($2 < 0 ? 0 : $2), $1 }' <(echo "$w") <(echo "$u") | sort -k1,1n -k2,2 | awk '{ print $2 }')
    [ -n "$targets" ] || continue
    # hottest source first; within an account, coordinators (*-lead, release) last
    while read -r key name st pid a; do
      [ -n "$key" ] || continue
      grep -qx "$a" <<<"$hot" || continue
      [ "$(verdict "$key" "$name" "$st" "$pid")" = ok ] || continue
      for t in $targets; do
        [ "${load[$t]:-0}" -lt "$PER_TARGET" ] || continue
        trusted "$pid" "$t" || continue
        load[$t]=$(( ${load[$t]:-0} + 1 )); echo "$key $name $a $t"; n=$((n + 1)); break
      done
      [ "$n" -ge "$MAX" ] && break
    done < <(while read -r key name st pid a; do
               [ -n "$key" ] || continue
               c=0; [[ $name == *-lead || $name == release ]] && c=1
               pct=$(awk -v a="$a" '$1 == a { print $2 }' <<<"$u")
               echo "${pct:--1} $c $key $name $st $pid $a"; done <<<"$p" |
             sort -k1,1nr -k2,2n | cut -d' ' -f3-)
    [ "$n" -ge "$MAX" ] && break
  done < <(cfg '.pools | keys[]')
}

launch() { # key sid name acct argv-rest
  local key=$1 sid=$2 name=$3 acct=$4 rest=$5 s id
  s=${key%%/*} id=${key#*/}
  # Type only once the pane's shell owns the foreground again (process-info: foreground pgid == shell pid), so the
  # line is not lost while the shell is still redrawing after claude exits.
  local _w fg sh
  for _w in $(seq 30); do
    read -r fg sh < <(hs "$s" pane process-info --pane "$id" 2>/dev/null |
      jq -r '.result.process_info | "\(.foreground_process_group_id) \(.shell_pid)"')
    [ -n "$fg" ] && [ "$fg" = "$sh" ] && break; sleep 0.5
  done
  # ...and the shell has finished its prompt hooks: no child process for two checks in a row (direnv's reload of a
  # devenv environment can take over a minute, and a line typed meanwhile is lost). The wait is at most 180 s.
  local quiet=0
  for _w in $(seq 360); do
    if [ -z "$(pgrep -P "$sh" 2>/dev/null)" ]; then quiet=$((quiet + 1)); [ "$quiet" -ge 2 ] && break; else quiet=0; fi
    sleep 0.5
  done
  sleep 1
  # `pane run` sends the text and Enter in one call; separate send-text + send-keys could land Enter first.
  hs "$s" pane run "$id" "$(launch_env "$acct") claude --resume $sid -n $name$rest" >/dev/null 2>&1
  # Success is TYPED, not read off the screen: within 60 s the pane's claude process has registered this same
  # session id in Claude Code's session registry, runs on the intended config dir, and is still alive 5 s later.
  local _i p dir want reg dbg; dbg=$state_dir/launch-debug.log
  [ "$acct" = default ] && want="" || want=$(cfgdir "$acct")
  for _i in $(seq 60); do sleep 1
    p=$(pane_pid "$s" "$id") || continue; [ -n "$p" ] || continue
    reg=$(jq -r '.sessionId // empty' "$HOME/.claude/sessions/$p.json" 2>/dev/null)
    [ "$reg" = "$sid" ] || continue
    dir=$(tr '\0' '\n' <"/proc/$p/environ" 2>/dev/null | sed -n 's/^CLAUDE_CONFIG_DIR=//p')
    [ "$dir" = "$want" ] || { echo "$(date -Is) $key $name $acct: config dir '$dir' != '$want' (pid $p)" >>"$dbg"; return 1; }
    sleep 5; kill -0 "$p" 2>/dev/null && return 0
    echo "$(date -Is) $key $name $acct: pid $p registered $sid but exited within 5 s" >>"$dbg"; return 1
  done
  echo "$(date -Is) $key $name $acct: no pid registered $sid within 60 s (last pane pid ${p:-none}, its registry sid '${reg:-none}')" >>"$dbg"
  return 1
}

# stdin = a pane screen. True when Claude Code's exit dialog "Background work is running" is open: its title alone
# on its line (spaces or a box edge around it).
bgwork_dialog() { grep -qE '^[[:space:]│]*Background work is running[[:space:]│]*$'; }
# stdin = a pane screen with that dialog: the items listed under "The following will stop when you exit:", up to the
# first numbered option, joined with "; ".
bgwork_tasks() {
  awk '/will stop when you exit:/ { f = 1; next }
       f && /^[[:space:]│]*(❯[[:space:]]*)?[0-9]+\./ { exit }
       f { gsub(/^[[:space:]│]+|[[:space:]│]+$/, ""); if ($0 != "") out = out (out ? "; " : "") $0 }
       END { print substr(out, 1, 200) }'
}

move() { # <session>/<pane> to -> one log line
  local key=$1 to=$2 s id name st pid from argv rest sid ultra="" v
  # The pane is looked up among the panes of RUNNING sessions only, so a typed session name never reaches herdr.
  read -r _ name st pid from < <(panes | awk -v k="$key" '$1 == k')
  [ -n "${pid:-}" ] || { echo "$key: SKIP no claude process in a running session"; return 0; }
  s=${key%%/*} id=${key#*/}
  [ "$to" = same ] && to=$from                     # restart in place (reloads settings)
  [ "$from" != "$to" ] || [ "${RESTART:-0}" = 1 ] || { echo "$key $name: SKIP already on $to"; return 0; }
  if [ "$from" != "$to" ]; then
    [ -n "$(pool_of "$to")" ] || { echo "$key $name: SKIP $to is not a pool member"; return 0; }
    [ "$(pool_of "$from")" = "$(pool_of "$to")" ] || { echo "$key $name: SKIP $from and $to are not in one pool"; return 0; }
  fi
  v=$(verdict "$key" "$name" "$st" "$pid"); [ "$v" = ok ] || { echo "$key $name: SKIP $v"; return 0; }
  trusted "$pid" "$to" || { echo "$key $name: SKIP $to has not trusted $(readlink "/proc/$pid/cwd")"; return 0; }
  argv=$(hs "$s" pane process-info --pane "$id" | jq -r --argjson p "$pid" \
    '.result.process_info.foreground_processes[] | select(.pid == $p) | .argv[1:] | @sh')
  # keep the session's own flags except --resume/-n, which are rebuilt
  rest=$(eval "set -- $argv"; out=""; while [ $# -gt 0 ]; do case $1 in
           # --resume/-r may come with no value (claude --resume opens the picker): drop the flag, and the
           # next word only when it isn't another flag. -n/--name always take one. Never `shift 2`: with one
           # word left it fails without shifting, and the loop never ends.
           --resume|-r) shift; [ $# -gt 0 ] && [[ $1 != -* ]] && shift ;;
           -n|--name) shift; [ $# -gt 0 ] && shift ;;
           -c|--continue) shift ;;
           *) out+=" $(printf %q "$1")"; shift ;; esac; done; echo "$out")
  hs "$s" pane read "$id" --source visible --lines 6 2>/dev/null | grep -q ultracode && ultra=1
  # The resume id comes from Claude Code's own session registry, read and saved BEFORE /exit, never from the screen
  # after it. Then /exit is confirmed by the process ending, not by screen text. If the process is still alive,
  # something stopped the exit: report it, type nothing more, and leave the session as it is.
  sid=$(jq -r '.sessionId // empty' "$HOME/.claude/sessions/$pid.json" 2>/dev/null)
  [[ $sid =~ ^[0-9a-f-]{36}$ ]] || { echo "$key $name: SKIP no session-registry entry for pid $pid; not touched"; return 0; }
  echo "$(date -Is) $key $name pid $pid sid $sid (saved before /exit)" >>"$state_dir/resume-ids.log"
  hs "$s" pane run "$id" "/exit" >/dev/null 2>&1
  # A session holding scheduled tasks, background shells or agents gets Claude Code's "Background work is
  # running" dialog on /exit. Exiting would stop them, and moving to background would leave a second copy
  # running, so the move is skipped: Esc cancels that dialog and the session keeps running where it is.
  local _k scr tasks
  for _k in $(seq 15); do
    timeout 2 tail --pid="$pid" -f /dev/null 2>/dev/null && break
    scr=$(hs "$s" pane read "$id" --source visible --lines 30 2>/dev/null)
    bgwork_dialog <<<"$scr" || continue
    tasks=$(bgwork_tasks <<<"$scr")
    hs "$s" pane send-keys "$id" esc >/dev/null 2>&1; sleep 2
    if kill -0 "$pid" 2>/dev/null && ! hs "$s" pane read "$id" --source visible --lines 30 2>/dev/null | bgwork_dialog; then
      echo "$key $name: SKIP background work would stop on exit (${tasks:-list not read}); Esc closed the exit dialog, session still running on $from"
      return 0
    fi
    echo "$key $name: FAIL the 'Background work is running' dialog did not close after Esc; sid $sid"
    return 1
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "$key $name: FAIL /exit did not end pid $pid in 30 s (a dialog is open?); session still running, nothing else typed; sid $sid"
    return 1
  fi
  if ! launch "$key" "$sid" "$name" "$to" "$rest"; then
    sleep 2; hs "$s" pane send-keys "$id" ctrl+c >/dev/null 2>&1; sleep 2
    launch "$key" "$sid" "$name" "$from" "$rest" && echo "$key $name: FAIL on $to, resumed back on $from ($sid)" ||
      echo "$key $name: FAIL on $to AND on $from — session $sid is stopped; resume it by hand"
    return 1
  fi
  [ -n "$ultra" ] && { hs "$s" pane run "$id" "/effort ultracode" >/dev/null 2>&1; sleep 2; }
  sleep 3
  local why="account balancing moved this session from $from to $to"
  [ "$from" = "$to" ] && why="this session was restarted on $to to load new settings"
  hs "$s" agent prompt "$id" "Note: $why; your conversation is intact. Carry on exactly where you stopped. Check for any background work you had running before starting it again; never start a second copy." >/dev/null 2>&1
  echo "$key $name: $from -> $to ($sid)"
}

# lock <-n | seconds>: the one balancer lock, on fd 9, held until the process exits
lock() {
  exec 9>"$lock_file"
  if [ "$1" = -n ]; then flock -n 9; else flock -w "$1" 9; fi
}

help() { cat <<'EOF'
  account-balance status                         every Claude pane: account, herdr status, verdict
  account-balance plan  [--max N]                the moves an apply run would make now (changes nothing)
  account-balance apply [--max N]                make those moves, one at a time
  account-balance move <session>/<pane> <acct>   move one pane (same safety checks)
  account-balance restart <session>/<pane>       restart one pane on its own account (reloads settings)
  account-balance usage | weekly                 the usage readings of the pool members
  account-balance pause <set_by> <hours> <reason> | unpause
EOF
}

cmd=${1:-status}; shift || true
while [ $# -gt 0 ]; do case $1 in --max) MAX=$2; shift 2 ;; *) break ;; esac; done
case $cmd in
  status) status ;;
  usage) usage ;;
  weekly) weekly ;;
  pause) # pause <set_by> <hours> <reason...>
    [ $# -ge 3 ] || { echo "usage: account-balance pause <set_by> <hours> <reason>" >&2; exit 2; }
    by=$1 h=$2; shift 2; now=$(date +%s)
    jq -n --arg by "$by" --arg r "$*" --argjson at "$now" --argjson rv "$(( now + h * 3600 ))" \
      '{v:1, set_by:$by, set_at:$at, reason:$r, review_by:$rv}' >"$state_dir/moves-paused.json.tmp" &&
      mv "$state_dir/moves-paused.json.tmp" "$state_dir/moves-paused.json" && echo paused ;;
  unpause) rm -f "$state_dir/moves-paused.json" && echo unpaused ;;
  plan) plan ;;
  move|restart)
    { [ $# -ge 1 ] && [[ $1 == */* ]] && { [ "$cmd" = restart ] || [ $# -ge 2 ]; }; } || { help >&2; exit 2; }
    lock 600 || { echo "account-balance: $lock_file is still held after 600 s; $1 not touched" >&2; exit 1; }
    if [ "$cmd" = move ]; then r=$(move "$1" "$2"); rc=$?; tag=""
    else r=$(RESTART=1 move "$1" same); rc=$?; tag="restart "; fi
    echo "$r"; echo "$(date -Is) $tag$r" >>"$log_file"; exit $rc ;;
  apply)
    rc=0
    # one balancer run at a time: an apply that finds the lock taken exits at once
    lock -n || { echo "another account-balance run holds $lock_file; skipped"; exit 0; }
    # One row per pool member per run; the header line at the top of usage.tsv names the columns.
    # five_hour_pct is rate_limits.five_hour.used_percentage, or "absent" (no usage-latest.json yet) or "none" (the
    # file has no five_hour reading); neither is 0%. saved_at/resets_at are epoch seconds ("-" when absent, 0 when
    # the field is missing). week_pct/week_resets_at come from rate_limits.seven_day the same way.
    t=$state_dir/usage.tsv
    [ -s "$t" ] || echo "run_time account five_hour_pct age_min saved_at resets_at week_pct week_resets_at" >"$t"
    { u=$(usage); ts=$(date -Is)
      while read -r a; do
        row=$(awk -v a="$a" '$1 == a' <<<"$u")
        if [ -z "$row" ]; then echo "$ts $a absent - - - - -"
        else read -r _ pct age saved resets <<<"$row"; [ "$pct" = -1 ] && pct=none
          wk=$(jq -r '[(.rate_limits.seven_day.used_percentage // "none" | if type == "number" then floor else . end),
                       (.rate_limits.seven_day.resets_at // 0)] | join(" ")' "$(cfgdir "$a")/usage-latest.json" 2>/dev/null)
          [ -n "$wk" ] || wk="none 0"
          echo "$ts $a $pct $age $saved $resets $wk"; fi
      done < <(members); } >>"$t"
    # Moves paused: plan and report only. The pause is a typed record, moves-paused.json:
    #   {"v":1,"set_by":"<session>","set_at":<epoch s>,"reason":"…","review_by":<epoch s>}
    # Past review_by it is reported as OVERDUE every run. A malformed record still pauses (fail closed).
    pf=$state_dir/moves-paused.json
    if [ -e "$pf" ]; then
      p=$(plan | tr '\n' ';')
      info=$(jq -r --argjson now "$(date +%s)" '"by \(.set_by) at \(.set_at|strflocaltime("%H:%M")) (\(.reason)); review by \(.review_by|strflocaltime("%H:%M"))\(if $now > .review_by then " — OVERDUE" else "" end)"' "$pf" 2>/dev/null) ||
        info="UNREADABLE pause record (still paused)"
      echo "MOVES PAUSED $info: would move: ${p:-nothing}"; exit 0
    fi
    while read -r key name from to; do
      [ -n "$key" ] || continue
      r=$(move "$key" "$to"); rc=$?; echo "$r"; echo "$(date -Is) $r" >>"$log_file"
      [ $rc -eq 0 ] || { echo "circuit breaker: stopping after a failed move"; break; }
    done < <(plan)
    exit $rc ;;
  *) help; exit 2 ;;
esac
