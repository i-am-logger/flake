#!/usr/bin/env bash
# account-balance's check (review condition C9), against the stub herdr on PATH.
#
#   BALANCE="<balancer command>" WORK=<new folder> bash check.sh
#
# Fixture: herdr sessions s1 (default) and s2, each with pane p1, both on hot cdev1; a stopped session s3; and a
# held session aether5d whose pane is on cdev1 too. Usage: cdev1 85% (hot), cdev2 20%, cdev3 5% but 3 h stale,
# default (~/.claude) 10%, and a folder outside the pool, ~/.claude-cdev9, at 0%.
# Expected: s1/p1 -> default (coolest fresh member under LOW), s2/p1 -> cdev2; nothing else.
set -u
read -ra BAL <<<"${BALANCE:?BALANCE must name the balancer command}"
W=${WORK:?WORK must name a new folder}
mkdir -p "$W"
export HOME=$W/home HERDR_STUB_DIR=$W/stub
state=$HOME/.local/state/account-balance
mkdir -p "$HOME/.claude/sessions" "$HERDR_STUB_DIR" "$state" "$W/proj"

cleanup() {
  local p
  for p in $(cat "$HERDR_STUB_DIR/spawned" 2>/dev/null) ${hold:-} ${shellpid:-}; do kill "$p" 2>/dev/null; done
}
trap cleanup EXIT

# spawn <pidfile> <cwd> <config-dir|->: as the stub's own spawn
spawn() {
  local pf=$1 cwd=$2 dir=$3
  : >"$pf"
  (
    cd "$cwd" || exit 1
    if [ "$dir" = - ]; then unset CLAUDE_CONFIG_DIR; else export CLAUDE_CONFIG_DIR=$dir; fi
    sleep 600 &
    echo $! >"$pf"
    wait
  ) </dev/null >/dev/null 2>&1 &
  until [ -s "$pf" ]; do sleep 0.05; done
}

now=$(date +%s)
usage_file() { # <folder> <5h%> <saved_at> <weekly%>
  mkdir -p "$1"
  jq -n --argjson f "$2" --argjson s "$3" --argjson w "$4" \
    '{saved_at: $s, rate_limits: {five_hour: {used_percentage: $f, resets_at: ($s + 3600)},
      seven_day: {used_percentage: $w, resets_at: ($s + 86400)}}}' >"$1/usage-latest.json"
}
usage_file "$HOME/.claude-cdev1" 85 "$now" 40
usage_file "$HOME/.claude-cdev2" 20 "$now" 10
usage_file "$HOME/.claude-cdev3" 5 "$((now - 3 * 3600))" 10
usage_file "$HOME/.claude" 10 "$now" 10
usage_file "$HOME/.claude-cdev9" 0 "$now" 0
trust=$(jq -n --arg w "$W/proj" '{projects: {($w): {hasTrustDialogAccepted: true}}}')
for f in "$HOME/.claude.json" "$HOME"/.claude-cdev{1,2,3,9}/.claude.json; do echo "$trust" >"$f"; done

cat >"$HERDR_STUB_DIR/sessions.json" <<'EOF'
{"sessions":[
 {"name":"s1","running":true,"default":true},
 {"name":"s2","running":true,"default":false},
 {"name":"s3","running":false,"default":false},
 {"name":"aether5d","running":true,"default":false}]}
EOF
sleep 600 & shellpid=$!
echo "$shellpid" >"$HERDR_STUB_DIR/shell.pid"

i=0
for row in s1:alpha s2:beta aether5d:gamma s3:delta; do
  s=${row%%:*} name=${row#*:} i=$((i + 1))
  d=$HERDR_STUB_DIR/panes/$s/p1
  mkdir -p "$d"
  echo "$name" >"$d/title"; echo idle >"$d/status"; echo "$W/proj" >"$d/cwd"; : >"$d/pid"
  [ "$s" = s3 ] && continue
  spawn "$d/pid" "$W/proj" "$HOME/.claude-cdev1"
  cat "$d/pid" >>"$HERDR_STUB_DIR/spawned"
  jq -n --arg s "aaaaaaaa-0000-4000-8000-00000000000$i" '{sessionId: $s}' >"$HOME/.claude/sessions/$(cat "$d/pid").json"
done

bal() { "${BAL[@]}" "$@" 2>&1; }

status_out=$(bal status)
plan_out=$(bal plan)

# a second apply while the lock is held
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

for v in status_out plan_out locked_out apply_out moves resumes calls; do
  echo "----- $v"; printf '%s\n' "${!v}"
done
echo "-----"

pass=0 fail=0
check() { # <name> <command...>
  local name=$1; shift
  if "$@"; then echo "PASS  $name"; pass=$((pass + 1)); else echo "FAIL  $name"; fail=$((fail + 1)); fi
}
row() { awk -v k="$1" -v t="$2" '$1 == k && $4 == t { f = 1 } END { exit !f }' <<<"$plan_out"; }
keys_separate() { grep -q '^s1/p1 ' <<<"$1" && grep -q '^s2/p1 ' <<<"$1"; }
logs_keyed() {
  grep -q ' s1/p1 ' <<<"$moves" && grep -q ' s2/p1 ' <<<"$moves" &&
    grep -q ' s1/p1 ' <<<"$resumes" && grep -q ' s2/p1 ' <<<"$resumes"
}
every_call_has_session() {
  awk '/^session list / { next } { for (i = 1; i < NF; i++) if ($i == "--session") next; bad = 1 } END { exit bad }' <<<"$calls"
}
sessions_running_only() {
  awk 'BEGIN { ok["s1"]; ok["s2"]; ok["aether5d"] }
       { for (i = 1; i < NF; i++) if ($i == "--session" && !($(i + 1) in ok)) bad = 1 } END { exit bad }' <<<"$calls"
}
held_untouched() {
  ! grep -q '^aether5d/' <<<"$plan_out" && ! grep -q 'aether5d/' <<<"$moves$resumes" &&
    ! grep -qE -- '--session aether5d (pane run|pane send-keys|agent prompt) ' <<<"$calls"
}
held_reported() { grep -qE '^ *aether5d/p1 gamma .* held$' <<<"$status_out"; }
coolest_first() { [ "$(head -1 <<<"$plan_out")" = "s1/p1 alpha cdev1 default" ]; }
locked_skips() { grep -q skipped <<<"$locked_out" && [ "$runs_locked" = "$runs_before" ]; }
never_target() { # <acct>
  ! awk -v a="$1" '$4 == a { f = 1 } END { exit !f }' <<<"$plan_out" && ! grep -q -- "-> $1 " <<<"$moves"
}
moves_done() { grep -q 's1/p1 alpha: cdev1 -> default ' <<<"$moves" && grep -q 's2/p1 beta: cdev1 -> cdev2 ' <<<"$moves"; }

check "keying: plan names s1/p1 and s2/p1 separately" keys_separate "$plan_out"
check "keying: moves.log and resume-ids.log name s1/p1 and s2/p1 separately" logs_keyed
check "herdr: every call but 'session list' carries --session" every_call_has_session
check "herdr: --session names only running sessions (never s3)" sessions_running_only
check "held: aether5d pane never planned, moved or typed into" held_untouched
check "held: status reports aether5d/p1 as held" held_reported
check "target: default is accepted as a target" row s1/p1 default
check "target: hot cdev1 pane goes to the coolest fresh member under LOW (default 10%)" coolest_first
check "lock: apply while balance.lock is held prints skipped and moves nothing" locked_skips
check "stale: cdev3 (5%, 3 h old) is never a target" never_target cdev3
check "pool: cdev9 (outside the pool, 0%) is never a target" never_target cdev9
check "apply: s1/p1 -> default and s2/p1 -> cdev2 completed" moves_done

echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
