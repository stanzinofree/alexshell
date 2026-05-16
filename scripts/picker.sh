#!/usr/bin/env bash
# fzf picker. Writes selection to /tmp/alexshell-selected on focus + enter.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVE="$ROOT/tools/active"
SEL="/tmp/alexshell-selected"

while true; do
  ls "$ACTIVE"/*.yaml 2>/dev/null \
    | xargs -n1 basename \
    | sed 's/\.yaml$//' \
    | fzf --reverse \
          --header='alexshell tools — focus to preview, enter to keep' \
          --preview="$ROOT/.venv/bin/python $ROOT/scripts/preview_help.py {}" \
          --preview-window=hidden \
          --bind "focus:execute-silent(echo {} > $SEL)" \
          --bind "enter:execute-silent(echo {} > $SEL)+abort" \
    || true
done
