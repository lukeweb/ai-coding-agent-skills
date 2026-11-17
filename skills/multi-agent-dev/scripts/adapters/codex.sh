#!/usr/bin/env bash
# Adapter for Codex CLI. Usage: codex.sh MODE BRIEF RESULT; WORKDIR is required.
set -u

[ "$#" -eq 3 ] || { echo "usage: codex.sh MODE BRIEF RESULT" >&2; exit 2; }
mode=$1
brief=$2
result=$3

case "$mode" in
  read) sandbox=read-only ;;
  write) sandbox=workspace-write ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

[ -n "${WORKDIR:-}" ] && [ -d "$WORKDIR" ] || {
  echo "WORKDIR missing or invalid" >&2
  exit 2
}
[ -s "$brief" ] || { echo "brief missing or empty: $brief" >&2; exit 2; }

if [ "$mode" = write ]; then
  top=$(git -C "$WORKDIR" rev-parse --show-toplevel 2>/dev/null) || {
    echo "write mode requires a Git worktree" >&2
    exit 2
  }
  [ "$(cd "$top" && pwd -P)" = "$(cd "$WORKDIR" && pwd -P)" ] || {
    echo "WORKDIR must be the worktree root" >&2
    exit 2
  }
fi

exec codex exec \
  --sandbox "$sandbox" \
  --config 'sandbox_workspace_write.writable_roots=[]' \
  --skip-git-repo-check \
  -C "$WORKDIR" \
  -o "$result" \
  - < "$brief"
