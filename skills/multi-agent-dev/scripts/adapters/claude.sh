#!/usr/bin/env bash
# Adapter for Claude Code CLI. Usage: claude.sh MODE BRIEF RESULT; WORKDIR is required.
set -u

[ "$#" -eq 3 ] || { echo "usage: claude.sh MODE BRIEF RESULT" >&2; exit 2; }
mode=$1
brief=$2
result=$3

case "$mode" in
  read)
    permission_mode=plan
    tools=(--restricted --tools "Read,Grep,Glob" --disallowedTools "mcp__*")
    ;;
  write)
    echo "Claude write mode is disabled: acceptEdits does not confine writes to WORKDIR" >&2
    exit 3
    ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

[ -n "${WORKDIR:-}" ] && [ -d "$WORKDIR" ] || {
  echo "WORKDIR missing or invalid" >&2
  exit 2
}
[ -s "$brief" ] || { echo "brief missing or empty: $brief" >&2; exit 2; }

cd "$WORKDIR" || { echo "cannot enter WORKDIR: $WORKDIR" >&2; exit 2; }
exec claude \
  -p \
  --permission-mode "$permission_mode" \
  --output-format text \
  "${tools[@]}" \
  < "$brief" > "$result"
