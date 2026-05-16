#!/usr/bin/env bash
# alexshell launcher — tmux 3-pane: shell | fzf picker | help viewer
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="alexshell"
ACTIVE="$ROOT/tools/active"
SEL="/tmp/alexshell-selected"

command -v tmux >/dev/null || { echo "tmux missing — brew install tmux"; exit 1; }
command -v fzf  >/dev/null || { echo "fzf missing — brew install fzf"; exit 1; }

first="$(ls "$ACTIVE"/*.yaml 2>/dev/null | head -1 | xargs -I{} basename {} .yaml || true)"
echo "${first:-}" > "$SEL"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -x 220 -y 50 -c "$ROOT"
tmux split-window -h -t "$SESSION":0 -p 45 -c "$ROOT"
tmux split-window -v -t "$SESSION":0.1 -p 60 -c "$ROOT"

tmux send-keys -t "$SESSION":0.1 "bash $ROOT/scripts/picker.sh" C-m
tmux send-keys -t "$SESSION":0.2 "bash $ROOT/scripts/watch_help.sh" C-m

tmux select-pane -t "$SESSION":0.0
tmux attach -t "$SESSION"
