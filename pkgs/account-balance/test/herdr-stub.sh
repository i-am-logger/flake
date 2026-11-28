# A stub `herdr` for account-balance's check. It never talks to a herdr server.
#
# State lives in $HERDR_STUB_DIR:
#   calls.log                     one line per call: its argv, printf %q, space-separated
#   sessions.json                 what `session list --json` prints (rows with name/running/default)
#   shell.pid                     a pid with no children, reported as every pane's shell
#   panes/<session>/<pane>/       title, status, cwd, pid (the pane's claude process, empty when none), and
#                                 optionally argv (a JSON array: the claude argv process-info reports)
#   launched                      each typed claude launch line, one per line
#   fail-dirs                     config dirs (or "-" for none) whose launched claude exits after 3 s
#
# A call without --session goes to the session marked default, as herdr's does. A call naming a session that is
# not running fails (real herdr would create it): calls.log is what the check reads to catch that.
# `pane run <pane> /exit` kills the pane's claude; `pane run <pane> "<env> claude --resume <sid> ..."` starts a new
# one with that env, cwd and a session-registry entry, so the balancer's typed launch checks see a real process.

D=${HERDR_STUB_DIR:?HERDR_STUB_DIR must be set}
{ printf '%q ' "$@"; echo; } >>"$D/calls.log"

session=""
if [ "${1:-}" = --session ]; then session=${2:-}; shift 2; fi

if [ "${1:-} ${2:-}" = "session list" ]; then cat "$D/sessions.json"; exit 0; fi

[ -n "$session" ] || session=$(jq -r '.sessions[] | select(.default == true) | .name' "$D/sessions.json")
if ! jq -e --arg s "$session" '.sessions[] | select(.name == $s and .running == true)' "$D/sessions.json" >/dev/null; then
  echo "herdr-stub: session '$session' is not running" >&2
  exit 1
fi
S=$D/panes/$session

# spawn <pidfile> <cwd> <config-dir|->: a stand-in claude process (a sleep, child of a subshell that reaps it)
spawn() {
  local pf=$1 cwd=$2 dir=$3 life=${4:-600}
  : >"$pf"
  (
    cd "$cwd" || exit 1
    if [ "$dir" = - ]; then unset CLAUDE_CONFIG_DIR; else export CLAUDE_CONFIG_DIR=$dir; fi
    sleep "$life" &
    echo $! >"$pf"
    wait
  ) </dev/null >/dev/null 2>&1 &
  until [ -s "$pf" ]; do sleep 0.05; done
}

alive_pid() { # <pane>: the pane's claude pid, when it is alive
  local p
  p=$(cat "$S/$1/pid" 2>/dev/null || true)
  if [ -n "$p" ] && kill -0 "$p" 2>/dev/null; then echo "$p"; fi
}

case "${1:-} ${2:-}" in
  "pane list")
    for d in "$S"/*/; do
      [ -d "$d" ] || continue
      p=$(basename "$d")
      jq -n --arg id "$p" --arg t "$(cat "$d/title")" --arg st "$(cat "$d/status")" --arg c "$(cat "$d/cwd")" \
        '{pane_id: $id, agent: "claude", agent_status: $st, cwd: $c, terminal_title: $t, terminal_title_stripped: $t}'
    done | jq -s '{result: {panes: .}}'
    ;;
  "pane process-info")
    shift 2; p=""
    while [ $# -gt 0 ]; do case $1 in --pane) p=$2; shift 2 ;; *) shift ;; esac; done
    sh=$(cat "$D/shell.pid")
    pid=$(alive_pid "$p")
    if [ -n "$pid" ]; then
      av=$(cat "$S/$p/argv" 2>/dev/null || jq -nc --arg t "$(cat "$S/$p/title")" '["/etc/profiles/per-user/logger/bin/claude", "-n", $t]')
      jq -n --argjson pid "$pid" --argjson sh "$sh" --argjson av "$av" \
        '{result: {process_info: {shell_pid: $sh, foreground_process_group_id: $pid,
          foreground_processes: [{pid: $pid, argv: $av}]}}}'
    else
      jq -n --argjson sh "$sh" \
        '{result: {process_info: {shell_pid: $sh, foreground_process_group_id: $sh, foreground_processes: []}}}'
    fi
    ;;
  "pane read")
    printf 'previous output\n\n❯ \n  ? for shortcuts\n'
    ;;
  "pane run")
    p=$3 cmd=$4
    case $cmd in
      /exit)
        pid=$(alive_pid "$p")
        if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; fi
        : >"$S/$p/pid"
        ;;
      *"claude --resume "*)
        sid=$(sed -E 's/.*--resume ([^ ]+).*/\1/' <<<"$cmd")
        case $cmd in
          "env -u CLAUDE_CONFIG_DIR "*) dir=- ;;
          CLAUDE_CONFIG_DIR=*) dir=${cmd#CLAUDE_CONFIG_DIR=}; dir=${dir%% *} ;;
          *) dir=- ;;
        esac
        echo "$cmd" >>"$D/launched"
        life=600; if grep -qxF -- "$dir" "$D/fail-dirs" 2>/dev/null; then life=3; fi
        spawn "$S/$p/pid" "$(cat "$S/$p/cwd")" "$dir" "$life"
        jq -n --arg s "$sid" '{sessionId: $s}' >"$HOME/.claude/sessions/$(cat "$S/$p/pid").json"
        cat "$S/$p/pid" >>"$D/spawned"
        ;;
    esac
    ;;
  "pane send-keys" | "agent prompt") ;;
  *)
    echo "herdr-stub: unsupported call: $*" >&2
    exit 2
    ;;
esac
