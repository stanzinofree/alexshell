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
# apply project-local config (-f is ignored when tmux server already running)
tmux source-file "$ROOT/scripts/tmux.conf"

# resolve actual window/pane indices (tmux base-index may be 0 or 1 server-wide)
W=$(tmux display-message -t "$SESSION" -p '#{window_index}')
P0=$(tmux display-message -t "$SESSION:$W" -p '#{pane_index}')

# split vertically (left | right)
tmux split-window -h -t "$SESSION:$W.$P0" -p 45 -c "$ROOT" -e "ALEXSHELL_ROOT=$ROOT"
P1=$(tmux display-message -t "$SESSION:$W" -p '#{pane_index}')

# split right pane horizontally (top | bottom)
tmux split-window -v -t "$SESSION:$W.$P1" -p 60 -c "$ROOT" -e "ALEXSHELL_ROOT=$ROOT"
P2=$(tmux display-message -t "$SESSION:$W" -p '#{pane_index}')

# right-top: fzf picker
tmux send-keys -t "$SESSION:$W.$P1" "bash $ROOT/scripts/picker.sh" C-m
# right-bottom: help viewer
tmux send-keys -t "$SESSION:$W.$P2" "bash $ROOT/scripts/watch_help.sh" C-m

# pane labels + border
tmux select-pane -t "$SESSION:$W.$P0" -T "[1] shell"
tmux select-pane -t "$SESSION:$W.$P1" -T "[2] list"
tmux select-pane -t "$SESSION:$W.$P2" -T "[3] help"
tmux set -g pane-border-status top

# rebind M-1/2/3 to actual pane indices (in case base-index shifted)
tmux bind -n M-1 select-pane -t "$SESSION:$W.$P0"
tmux bind -n M-2 select-pane -t "$SESSION:$W.$P1"
tmux bind -n M-3 select-pane -t "$SESSION:$W.$P2"

tmux select-pane -t "$SESSION:$W.$P0"
tmux attach -t "$SESSION"
