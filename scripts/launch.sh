#!/usr/bin/env bash
# alexshell launcher — tmux 3-pane: shell | fzf picker | help viewer
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SESSION="alexshell"
ACTIVE="$ROOT/tools/active"
SEL="/tmp/alexshell-selected"
export ALEXSHELL_ROOT="$ROOT"

command -v tmux >/dev/null || { echo "tmux missing — brew install tmux"; exit 1; }
command -v fzf  >/dev/null || { echo "fzf missing — brew install fzf"; exit 1; }

first="$(ls "$ACTIVE"/*.yaml 2>/dev/null | head -1 | xargs -I{} basename {} .yaml || true)"
echo "${first:-}" > "$SEL"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -x 220 -y 50 -c "$ROOT" -e "ALEXSHELL_ROOT=$ROOT"
# apply project-local config (-f is ignored when tmux server already running, so source explicitly)
tmux source-file "$ROOT/scripts/tmux.conf"
tmux split-window -h -t "$SESSION":0 -p 45 -c "$ROOT" -e "ALEXSHELL_ROOT=$ROOT"
tmux split-window -v -t "$SESSION":0.1 -p 60 -c "$ROOT" -e "ALEXSHELL_ROOT=$ROOT"

# right-top: fzf picker (pane 1)
tmux send-keys -t "$SESSION":0.1 "bash $ROOT/scripts/picker.sh" C-m
# right-bottom: help viewer (pane 2)
tmux send-keys -t "$SESSION":0.2 "bash $ROOT/scripts/watch_help.sh" C-m

# pane labels (visible top-left of each pane via select-pane -T)
tmux select-pane -t "$SESSION":0.0 -T "[1] shell"
tmux select-pane -t "$SESSION":0.1 -T "[2] list"
tmux select-pane -t "$SESSION":0.2 -T "[3] help"
tmux set -g pane-border-status top

tmux select-pane -t "$SESSION":0.0
tmux attach -t "$SESSION"
