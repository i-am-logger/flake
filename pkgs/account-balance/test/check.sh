#!/usr/bin/env bash
# account-balance's check (review condition C9), against the stub herdr on PATH. Usage comes from fixture
# ledger/accounts.tsv rows (cdev4 = default) written relative to "now"; rate = (100 - week%) / hours to reset.
#
#   BALANCE="<balancer command>" WORK=<new folder> bash check.sh
#
# Worlds, each its own HOME and stub herdr:
#   A  apply: s1/p1 alpha and s2/p1 beta (flags in its argv) on cdev1 (rate 0.4); a stopped s3; a held aether5d
#      pane. cdev2 50% resetting in 10 h (rate 5, no usage-latest.json), cdev3 20% in 80 h (1.0); default, cdev5,
#      cdev6 and cdev9 (outside the pool) rate higher but are never targets. Expected: alpha -> cdev2, beta -> cdev3.
#   P  plan only: the source pick, hysteresis, a stale reading and the usage-latest.json override.
#   D  plan only (+ paused applies): draining of the temporary accounts and the drain-after latch.
#   B  apply: three panes on default; launches on cdev1 and cdev2 fail, so the breaker stops after two.
set -u
read -ra BAL <<<"${BALANCE:?BALANCE must name the balancer command}"
W=${WORK:?WORK must name a new folder}
mkdir -p "$W/home"
export HOME=$W/home
cleanup() { local p; for p in $(cat "$W"/*/stub/spawned "$W"/*/stub/shell.pid 2>/dev/null) ${hold:-}; do kill "$p" 2>/dev/null; done; }
trap cleanup EXIT

spawn() { # <pidfile> <cwd> <config-dir|->: as the stub's own spawn
  local pf=$1 cwd=$2 dir=$3
  : >"$pf"
  ( cd "$cwd" || exit 1
    if [ "$dir" = - ]; then unset CLAUDE_CONFIG_DIR; else export CLAUDE_CONFIG_DIR=$dir; fi
    sleep 600 & echo $! >"$pf"; wait ) </dev/null >/dev/null 2>&1 &
  until [ -s "$pf" ]; do sleep 0.05; done
}
dirof() { [ "$1" = default ] && echo - || echo "$HOME/.claude-$1"; }

world() { # <name> <session[:stopped]>...: a new HOME and stub; the first session is herdr's default
  export HOME=$W/$1/home HERDR_STUB_DIR=$W/$1/stub; shift
  export ACCOUNT_BALANCE_LEDGER_DIR=$HOME/ledger
  state=$HOME/.local/state/account-balance
  mkdir -p "$HOME/.claude/sessions" "$HERDR_STUB_DIR" "$state" "$ACCOUNT_BALANCE_LEDGER_DIR" "$W/proj"
  local t a s first=true
  t=$(jq -n --arg w "$W/proj" '{projects: {($w): {hasTrustDialogAccepted: true}}}')
  echo "$t" >"$HOME/.claude.json"
  for a in cdev1 cdev2 cdev3 cdev5 cdev6 cdev9; do mkdir -p "$HOME/.claude-$a"; echo "$t" >"$HOME/.claude-$a/.claude.json"; done
  for s in "$@"; do
    jq -nc --arg n "${s%%:*}" --argjson r "$([ "${s#*:}" = stopped ] && echo false || echo true)" --argjson d $first \
      '{name: $n, running: $r, default: $d}'; first=false
  done | jq -s '{sessions: .}' >"$HERDR_STUB_DIR/sessions.json"
  sleep 600 & echo $! >"$HERDR_STUB_DIR/shell.pid"
}
nsid=0
pane() { # <session> <pane> <title> <acct|none> [argv JSON]
  local d=$HERDR_STUB_DIR/panes/$1/$2
  mkdir -p "$d"; echo "$3" >"$d/title"; echo idle >"$d/status"; echo "$W/proj" >"$d/cwd"; : >"$d/pid"
  [ -n "${5:-}" ] && echo "$5" >"$d/argv"
  [ "$4" = none ] && return
  spawn "$d/pid" "$W/proj" "$(dirof "$4")"; cat "$d/pid" >>"$HERDR_STUB_DIR/spawned"
  nsid=$((nsid + 1))
  jq -n --arg s "$(printf 'aaaaaaaa-0000-4000-8000-%012d' "$nsid")" '{sessionId: $s}' >"$HOME/.claude/sessions/$(cat "$d/pid").json"
}
iso() { date -u -d "@$1" +%Y-%m-%dT%H:%MZ; }
rtext() { TZ=America/Denver date -d "@$1" '+%b %-d, %-I%P (America/Denver)'; }
at_hour() { echo $(( (NOW / 3600 + $1) * 3600 )); }
tsv() { # <acct> <week%> <hours to reset> <age-min>, ...: the accounts.tsv rows, relative to NOW
  local a p h m
  while [ $# -ge 4 ]; do a=$1 p=$2 h=$3 m=$4; shift 4
    printf '%s\t%s\t%s\t%s\n' "$a" "$p" "$(rtext "$(at_hour "$h")")" "$(iso $((NOW - m * 60)))"
  done >"$ACCOUNT_BALANCE_LEDGER_DIR/accounts.tsv"
}
bal() { "${BAL[@]}" "$@" 2>&1; }
pass=0 fail=0
check() { # <name> <command...>
  local name=$1; shift
  if "$@"; then echo "PASS  $name"; pass=$((pass + 1)); else echo "FAIL  $name"; fail=$((fail + 1)); fi
}
show() { local v; for v in "$@"; do echo "----- $v"; printf '%s\n' "${!v}"; done; echo -----; }
is() { [ "$1" = "$2" ]; }

# ---- reset text, in its own zone
re1=$(bal reset-epoch "Nov 28, 5pm (America/Denver)" "$(date -d 2026-11-27T12:00Z +%s)")
re2=$(bal reset-epoch "Dec 2, 1pm (America/Denver)" "$(date -d 2026-11-27T12:00Z +%s)")
re3=$(bal reset-epoch "Jan 2, 1pm (America/Denver)" "$(date -d 2026-12-30T12:00Z +%s)")
show re1 re2 re3
check "reset: 'Nov 28, 5pm (America/Denver)' is 2026-11-29T00:00:00Z" is "$re1" "$(date -d 2026-11-29T00:00:00Z +%s)"
check "reset: 'Dec 2, 1pm (America/Denver)' is 2026-12-02T20:00:00Z" is "$re2" "$(date -d 2026-12-02T20:00:00Z +%s)"
check "reset: 'Jan 2' read on Dec 30 is next year's" is "$re3" "$(date -d 2027-01-02T20:00:00Z +%s)"

# ---- A: the main apply run
NOW=$(date +%s)
world A s1 s2 s3:stopped aether5d
pane s1 p1 alpha cdev1
pane s2 p1 beta cdev1 '["claude","--effort","ultracode","--autocompact","100000","--name","beta","--resume","OLD"]'
pane aether5d p1 gamma cdev1
pane s3 p1 delta none
tsv cdev1 60 100 10  cdev2 50 10 10  cdev3 20 80 10  cdev4 10 20 10  cdev5 0 10 10  cdev6 0 10 10  cdev9 0 10 10
status_out=$(bal status)
plan_out=$(bal plan)
(exec 8>"$state/balance.lock"; flock 8; exec sleep 60) & hold=$!
for _ in $(seq 100); do flock -n "$state/balance.lock" true || break; sleep 0.05; done
runs_before=$(grep -c ' pane run ' "$HERDR_STUB_DIR/calls.log")
locked_out=$(bal apply)
runs_locked=$(grep -c ' pane run ' "$HERDR_STUB_DIR/calls.log")
kill "$hold" 2>/dev/null; wait "$hold" 2>/dev/null
apply_out=$(bal apply)
moves=$(cat "$state/moves.log" 2>/dev/null)
resumes=$(cat "$state/resume-ids.log" 2>/dev/null)
calls=$(cat "$HERDR_STUB_DIR/calls.log")
launched=$(cat "$HERDR_STUB_DIR/launched" 2>/dev/null)
ledger=$(cat "$ACCOUNT_BALANCE_LEDGER_DIR/account-moves.tsv" 2>/dev/null)
hist=$(cat "$state/accounts-history.tsv" 2>/dev/null)
show status_out plan_out locked_out apply_out moves resumes launched ledger hist

row() { awk -v k="$1" -v t="$2" '$1 == k && $4 == t { f = 1 } END { exit !f }' <<<"$plan_out"; }
keys_separate() { grep -q '^s1/p1 ' <<<"$1" && grep -q '^s2/p1 ' <<<"$1"; }
logs_keyed() { grep -q ' s1/p1 ' <<<"$moves" && grep -q ' s2/p1 ' <<<"$moves" && grep -q ' s1/p1 ' <<<"$resumes" && grep -q ' s2/p1 ' <<<"$resumes"; }
every_call_has_session() { awk '/^session list / { next } { for (i = 1; i < NF; i++) if ($i == "--session") next; bad = 1 } END { exit bad }' <<<"$calls"; }
sessions_running_only() {
  awk 'BEGIN { ok["s1"]; ok["s2"]; ok["aether5d"] } { for (i = 1; i < NF; i++) if ($i == "--session" && !($(i + 1) in ok)) bad = 1 } END { exit bad }' <<<"$calls"
}
held_untouched() {
  ! grep -q '^aether5d/' <<<"$plan_out" && ! grep -q 'aether5d/' <<<"$moves$resumes" &&
    ! grep -qE -- '--session aether5d (pane run|pane send-keys|agent prompt) ' <<<"$calls"
}
held_reported() { grep -qE '^ *aether5d/p1 gamma .* held$' <<<"$status_out"; }
locked_skips() { grep -q skipped <<<"$locked_out" && [ "$runs_locked" = "$runs_before" ]; }
never_target() { # <acct>...
  local a; for a in "$@"; do awk -v a="$a" '$4 == a { f = 1 } END { exit !f }' <<<"$plan_out" && return 1; grep -q -- "-> $a " <<<"$moves" && return 1; done; return 0
}
moves_done() { grep -q 's1/p1 alpha: cdev1 -> cdev2 ' <<<"$moves" && grep -q 's2/p1 beta: cdev1 -> cdev3 ' <<<"$moves"; }
ledger_lines() {
  [ "$(wc -l <<<"$ledger")" = 2 ] &&
    awk -F'\t' 'NF == 6 && $2 == "s1/p1" && $3 == "alpha" && $4 == "cdev1" && $5 == "cdev2" && $6 == "ok" { a = 1 }
                NF == 6 && $2 == "s2/p1" && $3 == "beta" && $4 == "cdev1" && $5 == "cdev3" && $6 == "ok" { b = 1 } END { exit !(a && b) }' <<<"$ledger"
}
flags_kept() {
  local sid; sid=$(awk '$2 == "s2/p1" { print $7 }' <<<"$resumes" | tail -1)
  grep -qxF "CLAUDE_CONFIG_DIR=$HOME/.claude-cdev3 claude --resume $sid -n beta --effort ultracode --autocompact 100000" <<<"$launched" &&
    ! grep -q OLD <<<"$launched"
}
history_appended() { [ "$(grep -c . <<<"$hist")" = 7 ] && grep -q "^default	10	" <<<"$hist"; }

check "keying: plan names s1/p1 and s2/p1 separately" keys_separate "$plan_out"
check "keying: moves.log and resume-ids.log name s1/p1 and s2/p1 separately" logs_keyed
check "herdr: every call but 'session list' carries --session" every_call_has_session
check "herdr: --session names only running sessions (never s3)" sessions_running_only
check "held: aether5d pane never planned, moved or typed into" held_untouched
check "held: status reports aether5d/p1 as held" held_reported
check "lock: apply while balance.lock is held prints skipped and moves nothing" locked_skips
check "pick: weekly-weighted target, cdev2 (50%, 10 h, rate 5) before cdev3 (20%, 80 h, rate 1)" is "$(head -1 <<<"$plan_out")" "s1/p1 alpha cdev1 cdev2"
check "source: accounts.tsv is the source; cdev2 with no usage-latest.json is a target" row s1/p1 cdev2
check "never-target: default, cdev5 and cdev6 (rates 4.5, 10, 10) are never targets" never_target default cdev5 cdev6
check "pool: cdev9 (outside the pool, 0%) is never a target" never_target cdev9
check "apply: s1/p1 -> cdev2 and s2/p1 -> cdev3 completed" moves_done
check "ledger: one ok line per move in account-moves.tsv" ledger_lines
check "resume: --effort ultracode --autocompact 100000 and -n beta kept, new --resume sid, old --resume dropped" flags_kept
check "history: apply appends the accounts.tsv rows (cdev4 as default)" history_appended

# ---- P: plan-only picks
world P q
pane q p1 one cdev1
pane q p2 two cdev3
tsv cdev1 30 100 10  cdev2 50 5 10  cdev3 80 5 10  cdev4 95 100 10  cdev5 95 100 10  cdev6 95 100 10
p_pick=$(bal plan)
tsv cdev1 30 100 10  cdev2 50 40 10  cdev3 80 5 10  cdev4 95 100 10  cdev5 95 100 10  cdev6 95 100 10
p_hyst=$(bal plan)
tsv cdev1 30 100 10  cdev2 50 5 180  cdev3 90 5 10  cdev4 95 100 10  cdev5 95 100 10  cdev6 95 100 10
jq -n --argjson s "$NOW" --argjson r "$(at_hour 50)" '{saved_at: $s, rate_limits: {seven_day: {used_percentage: 0, resets_at: $r}}}' \
  >"$HOME/.claude-cdev3/usage-latest.json"
p_stale=$(bal plan)
show p_pick p_hyst p_stale
check "pick: source cdev1 (30%, 100 h, rate 0.7) moves; cdev3 (80%, 5 h, rate 4) stays" is "$p_pick" "q/p1 one cdev1 cdev2"
check "hysteresis: no move when the best target is within 2x (1.25 vs 0.7)" is "$p_hyst" ""
check "stale: cdev2 (3 h old) is never a target; a newer usage-latest.json overrides accounts.tsv (cdev3)" is "$p_stale" "q/p1 one cdev1 cdev3"

# ---- D: draining and the drain-after latch
world D d
pane d p1 tmp cdev5
tsv cdev1 50 100 10  cdev2 20 10 10  cdev3 60 100 10  cdev4 60 120 10  cdev5 0 10 10  cdev6 0 10 10
d_none=$(bal plan)
echo '{"v":1,"set_by":"check","set_at":0,"reason":"check","review_by":9999999999}' >"$state/moves-paused.json"
bal apply >/dev/null
latch1=$(cat "$state/drain-after.epoch" 2>/dev/null)
rows1=$(grep -c . "$state/accounts-history.tsv" 2>/dev/null)
tsv cdev1 50 100 10  cdev2 20 10 10  cdev3 60 268 10  cdev4 60 288 10  cdev5 0 10 10  cdev6 0 10 10
bal apply >/dev/null
latch2=$(cat "$state/drain-after.epoch" 2>/dev/null)
rows2=$(grep -c . "$state/accounts-history.tsv" 2>/dev/null)
h_old=$(iso $((NOW - 25 * 3600)))
for a in cdev1 cdev2 cdev3 default cdev5 cdev6; do printf '%s\t50\tx\t%s\n' "$a" "$h_old"; done >"$state/accounts-history.tsv"
d_hist=$(bal plan)
printf 'cdev1\t75\tx\t%s\n' "$(iso $((NOW - 5 * 3600)))" >>"$state/accounts-history.tsv"
d_hot=$(bal plan)
rm -f "$state/accounts-history.tsv"
want_latch=$(at_hour 120)
if [ -n "$latch1" ]; then
  NOW=$((latch1 + 60)); tsv cdev1 50 100 10  cdev2 20 10 10  cdev3 60 100 10  cdev4 60 120 10  cdev5 0 10 10  cdev6 0 10 10
  d_after=$(ACCOUNT_BALANCE_NOW=$NOW bal plan)
  NOW=$((latch1 - 3600)); tsv cdev1 50 100 10  cdev2 20 10 10  cdev3 60 100 10  cdev4 60 120 10  cdev5 0 10 10  cdev6 0 10 10
  d_before=$(ACCOUNT_BALANCE_NOW=$NOW bal plan)
else d_after="no latch" d_before="no latch"; fi
show d_none latch1 latch2 rows1 rows2 d_hist d_hot d_after d_before
check "drain: not yet (no 24 h of history, before the latch): cdev5 stays (rate 10 vs 8)" is "$d_none" ""
check "drain: 24 h of history all under 70% drains cdev5 -> cdev2" is "$d_hist" "d/p1 tmp cdev5 cdev2"
check "drain: a 75% reading in the last 24 h stops draining" is "$d_hot" ""
check "latch: drain-after.epoch is the later reset of cdev3 and default from accounts.tsv" is "$latch1" "$want_latch"
check "latch: next week's resets in a later accounts.tsv do not move it" is "$latch2" "$latch1"
check "history: rows keyed by account and read_at are appended once" is "$rows2/$rows1" "6/6"
check "drain: now >= the latched epoch drains cdev5 -> cdev2" is "$d_after" "d/p1 tmp cdev5 cdev2"
check "drain: now < the latched epoch does not" is "$d_before" ""

# ---- B: the breaker
NOW=$(date +%s)
world B b
pane b p1 one default
pane b p2 two default
pane b p3 three default
tsv cdev1 10 10 10  cdev2 20 10 10  cdev3 30 10 10  cdev4 95 100 10  cdev5 95 100 10  cdev6 95 100 10
printf '%s\n' "$HOME/.claude-cdev1" "$HOME/.claude-cdev2" >"$HERDR_STUB_DIR/fail-dirs"
b_plan=$(bal plan)
b_apply=$(bal apply)
b_ledger=$(cat "$ACCOUNT_BALANCE_LEDGER_DIR/account-moves.tsv" 2>/dev/null)
show b_plan b_apply b_ledger
breaker_at_2() {
  grep -q 'circuit breaker' <<<"$b_apply" && [ "$(grep -c . <<<"$b_ledger")" = 2 ] &&
    awk -F'\t' '$2 == "b/p1" && $6 == "resumed-back" { a = 1 } $2 == "b/p2" && $6 == "resumed-back" { b = 1 } $2 == "b/p3" { c = 1 }
                END { exit !(a && b && !c) }' <<<"$b_ledger"
}
check "breaker: trips after 2 failed moves (b/p1, b/p2 resumed back), not 1; b/p3 never tried" breaker_at_2

echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
