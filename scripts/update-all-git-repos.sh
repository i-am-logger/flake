#!/usr/bin/env bash
# Recursively reset and update all Git repos under a root directory.
# Environment variables:
#   DRY_RUN=1             -> print commands instead of executing
#   INCLUDE_UNTRACKED=1   -> also remove untracked files/dirs (git clean -fd)
#   DEFAULT_BRANCH=main   -> preferred branch name to switch to
#   USE_HTTPS_FETCH=1     -> rewrite SSH remotes to HTTPS for network ops (avoids YubiKey SSH touch)

set -u

ROOT="${1:-.}"
DRY_RUN="${DRY_RUN:-0}"
INCLUDE_UNTRACKED="${INCLUDE_UNTRACKED:-0}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
USE_HTTPS_FETCH="${USE_HTTPS_FETCH:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[DRY] %q ' "$@"; printf '\n'
  else
    "$@"
  fi
}

# Build per-host URL rewrite args to force HTTPS instead of SSH for fetches.
# Emits an array suitable for inlining into a git command: -c url.https://host/.insteadOf=ssh://user@host/ -c url.https://host/.insteadOf=user@host:
# Note: This does not persist config; it only affects the single git invocation.
make_https_rewrite_args() {
  local repo="$1"
  local -a args=()
  local remotes
  remotes="$(git -C "$repo" remote 2>/dev/null || true)"
  [[ -z "$remotes" ]] && {
    printf '%s\n' "${args[@]}"
    return 0
  }

  local r url user host
  # Use an assoc set of seen hosts+user to avoid duplicates (fallback if bash < 4: duplicates are harmless)
  declare -A seen=()
  for r in $remotes; do
    url="$(git -C "$repo" remote get-url "$r" 2>/dev/null || true)"
    user=""; host=""
    if [[ "$url" =~ ^ssh://([^@]+)@([^/]+)(/|$) ]]; then
      user="${BASH_REMATCH[1]}"; host="${BASH_REMATCH[2]}"
    elif [[ "$url" =~ ^([^@]+)@([^:]+):.+$ ]]; then
      # SCP-like syntax: user@host:path
      user="${BASH_REMATCH[1]}"; host="${BASH_REMATCH[2]}"
    fi
    if [[ -n "$host" ]]; then
      # Default user if missing
      [[ -z "$user" ]] && user="git"
      if [[ -z "${seen["$user@$host"]+x}" ]]; then
        seen["$user@$host"]=1
        args+=( -c "url.https://$host/.insteadOf=ssh://$user@$host/" )
        args+=( -c "url.https://$host/.insteadOf=$user@$host:" )
      fi
    fi
  done
  printf '%s\n' "${args[@]}"
}

is_git_work_tree() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

first_remote() {
  git -C "$1" remote 2>/dev/null | head -n1
}

detect_target_branch() {
  local repo="$1" remote="$2" target="$DEFAULT_BRANCH"

  # If preferred branch exists on remote, use it
  if git -C "$repo" show-ref --verify --quiet "refs/remotes/${remote}/${target}"; then
    echo "$target"
    return 0
  fi

  # Otherwise, try remote HEAD (default branch)
  local head_ref
  head_ref="$(git -C "$repo" symbolic-ref -q --short "refs/remotes/${remote}/HEAD" 2>/dev/null || true)"
  if [[ -n "$head_ref" ]]; then
    echo "${head_ref#${remote}/}"
    return 0
  fi

  # Fallback to master if present
  if git -C "$repo" show-ref --verify --quiet "refs/remotes/${remote}/master"; then
    echo "master"
    return 0
  fi

  # As a last resort, return preferred even if it's missing; caller will skip if not found
  echo "$target"
  return 0
}

abort_in_progress_ops() {
  local repo="$1"
  # Abort merge/rebase if in progress (ignore errors)
  git -C "$repo" merge --abort >/dev/null 2>&1 || true
  git -C "$repo" rebase --abort >/dev/null 2>&1 || true
}

# Find both .git directories and .git files (submodules/worktrees use a .git file)
# Avoid descending into .git internals by pruning paths that contain "/.git/"
mapfile -t git_entries < <(find "$ROOT" -path '*/.git/*' -prune -o -name .git \( -type d -o -type f \) -print 2>/dev/null)

if [[ "${#git_entries[@]}" -eq 0 ]]; then
  echo "No Git repositories found under: $ROOT"
  exit 0
fi

for git_entry in "${git_entries[@]}"; do
  repo_dir="$(dirname "$git_entry")"

  # Validate it's a working tree
  if ! is_git_work_tree "$repo_dir"; then
    # Not a normal work tree (could be bare repo internals), skip
    continue
  fi

  echo
  echo "=== Repo: $repo_dir ==="

  # Determine remote
  remote="$(first_remote "$repo_dir")"
  if [[ -z "$remote" ]]; then
    echo "No remotes configured. Skipping."
    continue
  fi

  # Fetch latest refs and tags
  if [[ "$USE_HTTPS_FETCH" == "1" ]]; then
    # Build temporary URL rewrite args to avoid SSH (and YubiKey touch) during network ops
    # Also force non-interactive HTTPS by disabling terminal/askpass prompts; relies on cached creds.
    # shellcheck disable=SC2207
    REWRITE_ARGS=($(make_https_rewrite_args "$repo_dir"))
    run env GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false git -C "$repo_dir" "${REWRITE_ARGS[@]}" --no-pager fetch --all --prune --tags || true
  else
    run git -C "$repo_dir" --no-pager fetch --all --prune --tags
  fi

  # Determine target branch
  target_branch="$(detect_target_branch "$repo_dir" "$remote")"

  # Ensure the remote target exists; otherwise skip
  if ! git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/${remote}/${target_branch}"; then
    echo "Remote branch ${remote}/${target_branch} not found. Skipping."
    continue
  fi

  # Make sure no merge/rebase in progress prevents checkout
  abort_in_progress_ops "$repo_dir"

  # Force-checkout target branch (create/reset to remote if necessary)
  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/${target_branch}"; then
    run git -C "$repo_dir" --no-pager checkout -f "${target_branch}"
  else
    run git -C "$repo_dir" --no-pager checkout -B "${target_branch}" "${remote}/${target_branch}"
  fi

  # Discard local changes and align exactly to remote
  run git -C "$repo_dir" reset --hard "${remote}/${target_branch}"

  # Optionally remove untracked files/dirs
  if [[ "$INCLUDE_UNTRACKED" == "1" ]]; then
    run git -C "$repo_dir" clean -fd
  fi

  # Brief summary
  run git -C "$repo_dir" --no-pager log --oneline -1 || true

done

echo
echo "Done."

