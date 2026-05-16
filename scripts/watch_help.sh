#!/usr/bin/env bash
# Render help for selected tool. Redraw only on change → no flicker.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEL="/tmp/alexshell-selected"
PREVIEW="$ROOT/scripts/preview_help.py"
PY="${ALEXSHELL_PY:-$ROOT/.venv/bin/python}"
[ -x "$PY" ] || PY="python3"

last=""
clear
while true; do
  cur=""
  [ -f "$SEL" ] && cur="$(cat "$SEL" 2>/dev/null)"
  if [ "$cur" != "$last" ]; then
    clear
    if [ -n "$cur" ]; then
      if command -v glow >/dev/null 2>&1; then
        "$PY" "$PREVIEW" "$cur" | glow -
      else
        "$PY" "$PREVIEW" "$cur"
      fi
    else
      echo "(no selection — focus fzf pane and pick a tool)"
    fi
    last="$cur"
  fi
  sleep 0.4
done
