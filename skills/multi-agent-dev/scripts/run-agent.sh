#!/usr/bin/env bash
# Usage: run-agent.sh AGENT MODE BRIEF RESULT [TIMEOUT_SECONDS]
# WORKDIR is required for write mode; read mode defaults to the current directory.
set -u
set -o pipefail
umask 077

fail() {
  echo "FAIL: $1" >&2
  exit "${2:-1}"
}

canonicalize_dir_path() {
  local path=$1 suffix="" component physical
  while [ ! -d "$path" ]; do
    [ "$path" != / ] || return 1
    component=${path##*/}
    suffix="/$component$suffix"
    path=${path%/*}
    [ -n "$path" ] || path=/
  done
  physical=$(cd "$path" && pwd -P) || return 1
  printf '%s%s' "$physical" "$suffix"
}

cleanup() {
  [ -z "${err_file:-}" ] || rm -f "$err_file"
  if [ "${lock_acquired:-0}" -eq 1 ]; then
    rmdir "$lock_dir" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

[ "$#" -ge 4 ] && [ "$#" -le 5 ] ||
  fail "usage: run-agent.sh AGENT MODE BRIEF RESULT [TIMEOUT]" 2

agent=$1
mode=$2
brief=$3
result=$4
limit=${5:-600}

case "$agent" in
  ""|*[!a-z0-9-]*) fail "invalid agent name" 2 ;;
esac
case "$mode" in
  read|write) ;;
  *) fail "MODE must be read or write" 2 ;;
esac
case "$limit" in
  ""|*[!0-9]*) fail "TIMEOUT must be a positive integer from 1 to 86400" 2 ;;
esac
[ "${#limit}" -le 5 ] || fail "TIMEOUT must be from 1 to 86400 seconds" 2
limit_num=$((10#$limit))
[ "$limit_num" -gt 0 ] && [ "$limit_num" -le 86400 ] ||
  fail "TIMEOUT must be a positive integer from 1 to 86400" 2

[ "$brief" != "$result" ] || fail "BRIEF and RESULT must be different files" 2

script_dir=$(cd "$(dirname "$0")" && pwd -P) || fail "cannot resolve script directory"
adapter="$script_dir/adapters/$agent.sh"
[ -x "$adapter" ] || fail "no executable adapter for '$agent'; agent unavailable" 2

cwd=$(pwd -P) || fail "cannot resolve current directory"
case "$brief" in /*) brief_input=$brief ;; *) brief_input="$cwd/$brief" ;; esac
case "$result" in /*) result_input=$result ;; *) result_input="$cwd/$result" ;; esac
brief_dir=$(cd "$(dirname "$brief_input")" 2>/dev/null && pwd -P) ||
  fail "brief directory does not exist" 2
brief_abs="$brief_dir/$(basename "$brief_input")"

[ -f "$brief_abs" ] && [ ! -L "$brief_abs" ] && [ -s "$brief_abs" ] ||
  fail "brief must be a non-empty regular file, not a symlink" 2

# Derive and validate the run root from the canonical brief path before creating results/.
case "$brief_dir" in
  */.agent-workflow/runs/*/briefs) ;;
  *) fail "BRIEF must be inside .agent-workflow/runs/RUN_ID/briefs" 2 ;;
esac
run_dir=${brief_dir%/briefs}
run_id=${run_dir##*/}
run_parent=${run_dir%/*}
[ "${run_parent##*/}" = runs ] || fail "invalid run directory" 2
workflow_parent=${run_parent%/*}
[ "${workflow_parent##*/}" = .agent-workflow ] || fail "invalid run directory" 2
[[ "$run_id" =~ ^[0-9]{8}-[0-9]{6}-[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
  fail "RUN_ID must use YYYYMMDD-HHMMSS-slug" 2
expected_result_dir="$run_dir/results"
result_parent=$(canonicalize_dir_path "${result_input%/*}") ||
  fail "cannot resolve RESULT directory"
[ "$result_parent" = "$expected_result_dir" ] ||
  fail "RESULT must be a direct file inside this run's results directory" 2
mkdir -p "$expected_result_dir" || fail "cannot create result directory"
result_dir=$(cd "$expected_result_dir" 2>/dev/null && pwd -P) || fail "cannot resolve result directory"
[ "$result_dir" = "$expected_result_dir" ] || fail "RESULT directory must not be a symlink"
result_abs="$result_dir/$(basename "$result_input")"
[ "$brief_abs" != "$result_abs" ] || fail "BRIEF and RESULT must be different files" 2
brief_name=${brief_abs##*/}
result_name=${result_abs##*/}
[ "$brief_name" = "$result_name" ] || fail "brief and result filenames must match" 2
[[ "$result_name" =~ ^T[0-9]{2,}-[a-z0-9-]+-[a-z0-9-]+-${agent}\.md$ ]] ||
  fail "filename must follow TASK-TYPE-ROLE-$agent.md" 2
task_id=${result_name%%-*}
for existing in "$brief_dir"/"$task_id"-*.md "$result_dir"/"$task_id"-*.md; do
  [ -e "$existing" ] || continue
  [ "$existing" = "$brief_abs" ] || [ "$existing" = "$result_abs" ] ||
    fail "TASK_ID is already used in this run: $task_id" 2
done

# Canonicalize the workspace and require an actual linked Git worktree for writes.
if [ "$mode" = write ]; then
  [ -n "${WORKDIR:-}" ] && [ -d "$WORKDIR" ] || fail "write mode requires an existing WORKDIR" 2
  top=$(git -C "$WORKDIR" rev-parse --show-toplevel 2>/dev/null) ||
    fail "WORKDIR is not inside a git repository" 2
  main=$(git -C "$top" worktree list --porcelain 2>/dev/null |
    awk '/^worktree / { print substr($0, 10); exit }')
  [ -n "$main" ] || fail "cannot determine primary working tree" 2
  top=$(cd "$top" && pwd -P) || fail "cannot resolve WORKDIR path"
  main=$(cd "$main" && pwd -P) || fail "cannot resolve primary working tree path"
  [ "$top" != "$main" ] || fail "WORKDIR is the primary working tree" 2
  git -C "$top" worktree list --porcelain | grep -Fqx "worktree $top" ||
    fail "WORKDIR is not a registered Git worktree" 2
  WORKDIR=$top
else
  WORKDIR=${WORKDIR:-$PWD}
  [ -d "$WORKDIR" ] || fail "WORKDIR does not exist" 2
  WORKDIR=$(cd "$WORKDIR" && pwd -P) || fail "cannot resolve WORKDIR path"
fi
export WORKDIR
[ -n "${HOME:-}" ] && [ -d "$HOME" ] || fail "HOME must be set to an existing CLI configuration directory"

# One exclusive lock per canonical workspace, shared across runs and roles.
lock_root="${TMPDIR:-/tmp}/multi-agent-workflow-locks-${UID:-$(id -u)}"
(umask 077; mkdir -p "$lock_root") || fail "cannot create workspace lock directory"
[ ! -L "$lock_root" ] && [ -d "$lock_root" ] && [ -O "$lock_root" ] ||
  fail "workspace lock directory is not a private directory owned by this user"
chmod 700 "$lock_root" || fail "cannot secure workspace lock directory"
workspace_key=$(printf '%s' "$WORKDIR" | cksum | awk '{print $1}')
lock_dir="$lock_root/$workspace_key.lock"
mkdir "$lock_dir" 2>/dev/null ||
  fail "workspace is locked by another agent or has a stale lock: $WORKDIR"
lock_acquired=1

if command -v timeout >/dev/null 2>&1; then
  tmo=$(command -v timeout)
elif command -v gtimeout >/dev/null 2>&1; then
  tmo=$(command -v gtimeout)
else
  fail "timeout command not found (macOS: install coreutils for gtimeout)" 2
fi
err_file=$(mktemp "${TMPDIR:-/tmp}/multi-agent-workflow.XXXXXX") || fail "cannot create temporary error log"

if [ -e "$result_abs" ] || [ -L "$result_abs" ]; then
  [ -f "$result_abs" ] && [ ! -L "$result_abs" ] || fail "existing RESULT is not a regular file" 2
  rm -f "$result_abs" || fail "cannot remove previous result file"
fi

# Do not pass ambient credentials or other inherited environment variables to peers.
# HOME remains for CLI installation/auth configuration; sensitive files in HOME still
# require an external OS/container boundary and must not be exposed to peer processes.
env -i \
  PATH="${PATH:-/usr/bin:/bin}" \
  HOME="$HOME" \
  TMPDIR="${TMPDIR:-/tmp}" \
  LANG="${LANG:-C}" \
  LC_ALL="${LC_ALL:-}" \
  TERM="${TERM:-dumb}" \
  WORKDIR="$WORKDIR" \
  "$tmo" --kill-after=10s "$limit_num" "$adapter" "$mode" "$brief_abs" "$result_abs" \
  2>"$err_file"
status=$?

if [ "$status" -ne 0 ]; then
  tail -n 20 "$err_file" >&2
  { [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; } &&
    fail "$agent timed out after ${limit_num}s (including termination grace period)"
  fail "$agent exited with status $status"
fi

[ -s "$result_abs" ] || fail "$agent produced no result file"
case "$(sed -n '1p' "$result_abs")" in
  '# Result: COMPLETE'|'# Result: PARTIAL'|'# Result: BLOCKED'|'# Result: FAILED') ;;
  *) fail "$agent result has an invalid or missing status line" ;;
esac
grep -qx '## Summary' "$result_abs" || fail "$agent result is missing the Summary section"
echo "OK: $result_abs"
