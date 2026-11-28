#!/usr/bin/env bash
# account-balance: move idle Claude sessions off accounts near their 5-hour or weekly limit.
#
#   account-balance status                         every Claude pane: account, herdr status, verdict
#   account-balance plan  [--max N]                the moves an apply run would make now (changes nothing)
#   account-balance apply [--max N]                make those moves, one at a time
#   account-balance move <session>/<pane> <acct>   move one pane (same safety checks)
#   account-balance restart <session>/<pane>       restart one pane on its own account (reloads settings)
#   account-balance usage                          the pool members' readings: week%, rate, age, 5-hour %
#   account-balance reset-epoch "<text>" <epoch>   the epoch of a reset text read at <epoch>
#   account-balance pause <set_by> <hours> <reason> | unpause
#
# Config is data written by the flake (ACCOUNT_BALANCE_CONFIG, JSON): pools of accounts, thresholds, and the
# held herdr sessions. An account is `default` (~/.claude, CLAUDE_CONFIG_DIR unset) or a name N (~/.claude-N).
# Usage is read from ledger/accounts.tsv (account, week%, reset text, read_at; cdev4 there is `default`), and
# a pool member's <folder>/usage-latest.json overrides its row when its saved_at is newer. Moves stay inside
# one pool, and only pool members are sources or targets.
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
# rate = (100 - week%) / max(hours to the weekly reset, 1). Sources: lowest rate first, a fresh reading only.
# Targets: highest rate first, fresh (<= stale_min minutes), under room % weekly and on the 5-hour reading (if
# any), never source_only or temporary accounts; a move S -> T needs rate(T) >= hysteresis x rate(S). While
# draining, the temporary accounts are sources ahead of all others (no hysteresis): when the history
# (accounts-history.tsv) covers 24 h with every pool reading in the last 24 h under room %, or from the
# latched drain-after.epoch (the later next reset of drain_after_resets_of, written once). At most
# per_target moves land on one account per run; `breaker` failed moves stop the run; a move whose new
# session does not come up is resumed again on its original account. One line per move attempt goes to
# ledger/account-moves.tsv.
#
# One lock (balance.lock in the state folder) is held for the whole of apply, move and restart: apply skips
# when it is taken, a manual move or restart waits up to 600 s for it.
set -uo pipefail

config=${ACCOUNT_BALANCE_CONFIG:?ACCOUNT_BALANCE_CONFIG must name the JSON config}
cfg() { jq -r "$1" "$config"; }
ROOM=$(cfg .thresholds.room) OVERFLOW=$(cfg .thresholds.overflow_home_over) HYST=$(cfg .thresholds.hysteresis) PER_TARGET=$(cfg .thresholds.per_target)
STALE_MIN=$(cfg .thresholds.stale_min) MAX=$(cfg .thresholds.max) BREAKER=$(cfg .thresholds.breaker)
NOT_TARGET=" $(cfg '(.source_only + .temporary)[]' | tr '\n' ' ')" TEMPORARY=" $(cfg '.temporary[]' | tr '\n' ' ')"
ledger_dir=${ACCOUNT_BALANCE_LEDGER_DIR:-$HOME/Code/logger/ledger}

state_dir=${ACCOUNT_BALANCE_STATE:-$HOME/.local/state/account-balance}
log_file=$state_dir/moves.log
skip_file=$state_dir/skip.txt
lock_file=$state_dir/balance.lock
hist_file=$state_dir/accounts-history.tsv
latch_file=$state_dir/drain-after.epoch
now_s() { echo "${ACCOUNT_BALANCE_NOW:-$(date +%s)}"; }
mkdir -p "$state_dir"

# every pool member, one per line; the members of one pool; the pool of an account (empty when none)
# Teams come from head's registry (ACCOUNT_BALANCE_REGISTRY, team-roles.toml): [teams.<team>] gives
# herdr_session and an optional workspace (the pane id's w-part, e.g. wA); [accounts.teams] gives each team's
# home accounts (<team> = [...]; head's, written with bin/registry-add). A team with no accounts entry has no home.
registry=${ACCOUNT_BALANCE_REGISTRY:-$HOME/Code/logger/team-roles.toml}
teams_json=$(taplo get -f "$registry" -o json 2>/dev/null |
  jq -c '(.accounts.teams // {}) as $a | (.teams // {}) | with_entries(.value.accounts = $a[.key])') || teams_json='{}'
[ -n "$teams_json" ] || teams_json='{}'
# Two teams on one session (or one session/workspace) is refused: a pane must match exactly one team.
overlap=$(jq -r '[to_entries[] | select(.value.accounts) | "\(.value.herdr_session)/\(.value.workspace // "*")"]
  | group_by(.) | map(select(length > 1)[0]) | join(" ")' <<<"$teams_json")
# every account any team, the config or accounts.tsv names, one per line (cdev4 is default): the drain's 24 h
# rule counts them all, and overflow may borrow any of them that isn't temporary or source-only
members() { { jq -r '.[] | .accounts[]?' <<<"$teams_json"; cfg '(.source_only + .temporary)[]'; tsv_rows | cut -f1; } | awk 'NF && !seen[$0]++'; }
# team_of <session> <pane id>: <session>/<workspace> beats <session>; empty when no team matches
team_of() {
  jq -r --arg s "$1" --arg w "${2%%:*}" '[to_entries[] | select(.value.accounts and .value.herdr_session == $s)]
    | (map(select(.value.workspace == $w)) + map(select(.value.workspace == null)))[0].key // empty' <<<"$teams_json"
}
# homes <team>: its temporaries until the 0188 drain, else its other accounts; never a source_only account
homes() {
  local a tmp=() own=()
  while read -r a; do [ -n "$a" ] || continue; [[ $NOT_TARGET == *" $a "* && $TEMPORARY != *" $a "* ]] && continue
    if [[ $TEMPORARY == *" $a "* ]]; then tmp+=("$a"); else own+=("$a"); fi
  done < <(jq -r --arg t "$1" '.[$t].accounts[]?' <<<"$teams_json")
  if [ ${#tmp[@]} -gt 0 ] && [ -z "${DRAINING:-}" ]; then printf '%s\n' "${tmp[@]}"; else printf '%s\n' "${own[@]}"; fi
}
held() { jq -e --arg s "$1" '.held_sessions | index($s) != null' "$config" >/dev/null; }
# A pane pinned to its account by its name (config pinned_name_prefixes: the Accounts consoles).
pinned() { jq -e --arg n "$1" 'any(.pinned_name_prefixes[]?; . as $p | $n | startswith($p))' "$config" >/dev/null; }

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

# reset_epoch "<text>" <read_at epoch>: "Nov 28, 5pm (America/Denver)" in the zone it names (UTC when none),
# in read_at's year, or the next one when that lands more than a day before read_at. A text with no date is
# read_at's day in that zone, or the next day.
reset_epoch() {
  local t=$1 r=$2 z d e y; z=$(sed -nE 's/.*\(([^)]+)\).*/\1/p' <<<"$t"); z=${z:-UTC}
  d=$(sed -E 's/\(.*//; s/,//g; s/^ +| +$//g' <<<"$t")
  if [[ $d =~ ^[A-Za-z]+\ [0-9]+\  ]]; then
    y=$(TZ=$z date -d "@$r" +%Y)
    e=$(date -d "TZ=\"$z\" ${d% *} $y ${d##* }" +%s) || return 1
    [ "$e" -ge $((r - 86400)) ] || e=$(date -d "TZ=\"$z\" ${d% *} $((y + 1)) ${d##* }" +%s) || return 1
  else
    e=$(date -d "TZ=\"$z\" $(TZ=$z date -d "@$r" +%F) $d" +%s) || return 1
    [ "$e" -ge "$r" ] || e=$((e + 86400))
  fi
  echo "$e"
}
# accounts.tsv rows with a numeric week%, cdev4 as default: "acct<TAB>pct<TAB>reset text<TAB>read_at"
tsv_rows() {
  awk -F'\t' -v OFS='\t' '$2 ~ /^[0-9.]+%?$/ { sub(/%$/, "", $2); if ($1 == "cdev4") $1 = "default"; print $1, $2, $3, $4 }' \
    "$ledger_dir/accounts.tsv" 2>/dev/null
}
# "<acct> <week%> <resets epoch> <read epoch> <5h%|-1>" per pool member with a reading: its latest accounts.tsv
# row, or its usage-latest.json when that was saved later. The 5-hour % is usage-latest.json's, while its window
# is open.
readings() {
  local rows a pct txt at r e f s w we fh now; rows=$(tsv_rows); now=$(now_s)
  while read -r a; do
    pct="" r=0 e=0 fh=-1
    IFS=$'\t' read -r _ pct txt at < <(awk -F'\t' -v a="$a" '$1 == a' <<<"$rows" | sort -t$'\t' -k4,4 | tail -1)
    if [ -n "$pct" ]; then
      { r=$(date -d "$at" +%s 2>/dev/null) && e=$(reset_epoch "$txt" "$r" 2>/dev/null); } || { pct="" r=0; }
    fi
    f=$(cfgdir "$a")/usage-latest.json
    if [ -r "$f" ]; then
      read -r s w we fh < <(jq -r --argjson now "$now" '"\(.saved_at // 0 | floor) \(.rate_limits.seven_day.used_percentage // -1)
        \(.rate_limits.seven_day.resets_at // 0 | floor) \(if (.rate_limits.five_hour.resets_at // 0) > $now
        then .rate_limits.five_hour.used_percentage // -1 else -1 end)"' "$f" | tr '\n' ' ')
      [ "$s" -gt "$r" ] && [ "$w" != -1 ] && { pct=$w e=$we r=$s; }
    fi
    if [ -n "$pct" ]; then echo "$a $pct $e $r ${fh:--1}"; fi
  done < <(members)
}
# usage: "<acct> <week%> <rate> <age-min> <5h%|-1>" per pool member with a reading
usage() {
  readings | awk -v now="$(now_s)" '{ h = ($3 - now) / 3600; if (h < 1) h = 1
    printf "%s %s %.4f %d %s\n", $1, $2, (100 - $2) / h, (now - $4) / 60, $5 }'
}
# The drain-after epoch: the latched one, else the later reset of drain_after_resets_of in accounts.tsv (empty
# until all have a row). latch writes it once.
drain_after() {
  [ -s "$latch_file" ] && { cat "$latch_file"; return; }
  local rows a row r e max=0
  rows=$(tsv_rows)
  while read -r a; do
    row=$(awk -F'\t' -v a="$a" '$1 == a' <<<"$rows" | sort -t$'\t' -k4,4 | tail -1)
    [ -n "$row" ] || return 0
    r=$(date -d "$(cut -f4 <<<"$row")" +%s 2>/dev/null) && e=$(reset_epoch "$(cut -f3 <<<"$row")" "$r" 2>/dev/null) || return 0
    [ "$e" -gt "$max" ] && max=$e
  done < <(cfg '.drain_after_resets_of[]')
  [ "$max" -gt 0 ] && echo "$max"
}
latch() { [ -s "$latch_file" ] && return 0; local e; e=$(drain_after); [ -z "$e" ] || echo "$e" >"$latch_file"; }
# appends the accounts.tsv rows not yet in the history (keyed by account and read_at)
hist_append() {
  touch "$hist_file"
  local new
  new=$(tsv_rows | awk -F'\t' 'FILENAME == ARGV[1] { k[$1 FS $4]; next } !(($1 FS $4) in k) { k[$1 FS $4]; print }' "$hist_file" -)
  [ -z "$new" ] || echo "$new" >>"$hist_file"
}
# true when the temporary accounts are drained: from the drain-after epoch, or once the history (with the current
# accounts.tsv rows) covers 24 h and every pool reading of the last 24 h is under room %
draining() {
  local now da rows; now=$(now_s); da=$(drain_after)
  [ -n "$da" ] && [ "$now" -ge "$da" ] && return 0
  rows=$({ cat "$hist_file" 2>/dev/null; tsv_rows; } | awk -F'\t' 'NF >= 4 && !seen[$1 FS $4]++')
  [ -n "$rows" ] || return 1
  while IFS=$'\t' read -r a p _ at; do echo "$a $p $(date -d "$at" +%s 2>/dev/null || echo x)"; done <<<"$rows" |
    awk -v now="$now" -v m=" $(members | tr '\n' ' ')" -v room="$ROOM" '$3 == "x" || !index(m, " " $1 " ") { next }
      { if (min == "" || $3 < min) min = $3 } $3 >= now - 86400 && $2 >= room { hot = 1 }
      END { exit !(min != "" && min <= now - 86400 && !hot) }'
}

# The claude process by its argv[0] basename: herdr reports the full path (/etc/profiles/per-user/<user>/bin/claude
# on ads-dev1), skyspy-dev's reference matched the bare name and so saw no pane here.
pane_pid() { hs "$1" pane process-info --pane "$2" 2>/dev/null |
  jq -r '.result.process_info.foreground_processes[]? | select((.argv[0] // "" | split("/") | last) == "claude") | .pid' | head -1; }

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
  pinned "$name" && { echo account-pinned; return; }
  [ -n "$(team_of "$s" "$id")" ] || { echo no-team; return; }
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
  echo "accounts (acct week% rate age-min 5h%), draining: $(draining && echo yes || echo no):"; echo "$u" | sort -k3 -g | sed 's/^/  /'
  echo "sessions (session/pane name status pid acct verdict):"
  panes | while read -r key name st pid a; do echo "  $key $name $st $pid $a $(verdict "$key" "$name" "$st" "$pid")"; done
}

# prints "<session>/<pane> <name> <from> <to>" lines. A pane's targets are its team's homes (homes()): a pane
# off them moves to the best home; a pane on one moves to another home only past the hysteresis; when every
# home is over overflow_home_over %, it borrows the coolest non-temporary, non-source-only account under room %.
plan() {
  local u p n=0 key name st pid a t c rk acct team h hm best mem
  declare -A load=() rate=() age=() week=() fh=()
  [ -z "$overlap" ] || { echo "refused: teams overlap on $overlap (a pane must match one team)" >&2; return 2; }
  u=$(usage); p=$(panes); draining && DRAINING=1
  while read -r acct w rk c f; do [ -n "$acct" ] && rate[$acct]=$rk age[$acct]=$c week[$acct]=$w fh[$acct]=$f; done <<<"$u"
  ok() { [ -n "${rate[$1]:-}" ] && [ "${age[$1]}" -le "$STALE_MIN" ] && awk -v w="${week[$1]}" -v f="${fh[$1]}" -v r="$ROOM" 'BEGIN { exit !(w < r && f < r) }'; }
  by_rate() { local x; for x in "$@"; do echo "${rate[$x]:-0} $x"; done | sort -k1,1gr -k2,2 | awk '{ print $2 }'; }
  while read -r rk _ c key name st pid a; do
    [ "$(verdict "$key" "$name" "$st" "$pid")" = ok ] || continue
    team=$(team_of "${key%%/*}" "${key#*/}"); mapfile -t hm < <(homes "$team"); [ ${#hm[@]} -gt 0 ] || continue
    best=""
    for t in $(by_rate "${hm[@]}"); do
      if ! { [ "$t" != "$a" ] && [ "${load[$t]:-0}" -lt "$PER_TARGET" ] && ok "$t"; }; then continue; fi
      if [[ " ${hm[*]} " == *" $a "* ]]; then  # on a home: only past the hysteresis
        awk -v t="${rate[$t]}" -v s="${rate[$a]:-0}" -v h="$HYST" 'BEGIN { exit !(t >= h * s) }' || continue
      fi
      trusted "$pid" "$t" || continue; best=$t; break
    done
    if [ -z "$best" ] && [[ " ${hm[*]} " == *" $a "* ]]; then  # overflow: every home over overflow_home_over %
      h=1; for t in "${hm[@]}"; do awk -v w="${week[$t]:-0}" -v o="$OVERFLOW" 'BEGIN { exit !(w > o) }' || h=0; done
      if [ "$h" = 1 ]; then
        mapfile -t mem < <(members)
        for t in $(by_rate "${mem[@]}"); do
          [[ " ${hm[*]} " != *" $t "* && $NOT_TARGET != *" $t "* ]] && [ "${load[$t]:-0}" -lt "$PER_TARGET" ] && ok "$t" && trusted "$pid" "$t" && { best=$t; break; }
        done
      fi
    fi
    [ -n "$best" ] || continue
    load[$best]=$(( ${load[$best]:-0} + 1 )); echo "$key $name $a $best"; n=$((n + 1))
    [ "$n" -ge "$MAX" ] && break
  done < <(while read -r key name st pid a; do
             [ -n "$key" ] || continue
             team=$(team_of "${key%%/*}" "${key#*/}"); [ -n "$team" ] || continue
             c=0; [[ $name == *-lead || $name == release ]] && c=1
             rk=1; [[ " $(homes "$team" | tr '\n' ' ') " == *" $a "* ]] || rk=0   # off its homes: first
             echo "$rk ${rate[$a]:-0} $c $key $name $st $pid $a"; done <<<"$p" | sort -k1,1n -k2,2g -k3,3n)
}

# ledger <session>/<pane> <name> <from> <to> <ok|failed|resumed-back>: one line per move attempt
ledger() { mkdir -p "$ledger_dir" && printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -Is)" "$@" >>"$ledger_dir/account-moves.tsv"; }

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
    [[ $NOT_TARGET == *" $to "* ]] && ! jq -e --arg t "$(team_of "$s" "$id")" --arg a "$to" '.[$t].accounts | index($a) != null' <<<"$teams_json" >/dev/null &&
      { echo "$key $name: SKIP $to is source-only, or another team's temporary"; return 0; }
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
    ledger "$key" "$name" "$from" "$to" failed; return 1
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "$key $name: FAIL /exit did not end pid $pid in 30 s (a dialog is open?); session still running, nothing else typed; sid $sid"
    ledger "$key" "$name" "$from" "$to" failed; return 1
  fi
  if ! launch "$key" "$sid" "$name" "$to" "$rest"; then
    sleep 2; hs "$s" pane send-keys "$id" ctrl+c >/dev/null 2>&1; sleep 2
    if launch "$key" "$sid" "$name" "$from" "$rest"; then
      echo "$key $name: FAIL on $to, resumed back on $from ($sid)"; ledger "$key" "$name" "$from" "$to" resumed-back
    else echo "$key $name: FAIL on $to AND on $from — session $sid is stopped; resume it by hand"; ledger "$key" "$name" "$from" "$to" failed; fi
    return 1
  fi
  [ -n "$ultra" ] && { hs "$s" pane run "$id" "/effort ultracode" >/dev/null 2>&1; sleep 2; }
  sleep 3
  local why="account balancing moved this session from $from to $to"
  [ "$from" = "$to" ] && why="this session was restarted on $to to load new settings"
  hs "$s" agent prompt "$id" "Note: $why; your conversation is intact. Carry on exactly where you stopped. Check for any background work you had running before starting it again; never start a second copy." >/dev/null 2>&1
  echo "$key $name: $from -> $to ($sid)"; ledger "$key" "$name" "$from" "$to" ok
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
  account-balance usage                          the pool members' readings: week%, rate, age, 5-hour %
  account-balance reset-epoch "<text>" <epoch>   the epoch of a reset text read at <epoch>
  account-balance pause <set_by> <hours> <reason> | unpause
EOF
}

cmd=${1:-status}; shift || true
while [ $# -gt 0 ]; do case $1 in --max) MAX=$2; shift 2 ;; *) break ;; esac; done
case $cmd in
  status) status ;;
  usage) usage ;;
  reset-epoch) [ $# -eq 2 ] || { help >&2; exit 2; }; reset_epoch "$1" "$2" ;;
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
    hist_append; latch
    # One row per pool member per run (rates.tsv): its reading, or "absent" when it has none.
    t=$state_dir/rates.tsv
    [ -s "$t" ] || echo "run_time account week_pct rate age_min five_hour_pct" >"$t"
    { u=$(usage); ts=$(date -Is)
      while read -r a; do row=$(awk -v a="$a" '$1 == a' <<<"$u"); echo "$ts ${row:-$a absent - - -}"; done < <(members); } >>"$t"
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
    fails=0
    while read -r key name from to; do
      [ -n "$key" ] || continue
      r=$(move "$key" "$to"); mrc=$?; echo "$r"; echo "$(date -Is) $r" >>"$log_file"
      [ $mrc -eq 0 ] && continue
      rc=1; fails=$((fails + 1))
      [ "$fails" -ge "$BREAKER" ] && { echo "circuit breaker: stopping after $fails failed moves"; break; }
    done < <(plan)
    exit $rc ;;
  *) help; exit 2 ;;
esac
