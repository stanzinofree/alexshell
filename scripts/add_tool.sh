#!/usr/bin/env bash
# Scaffold a new tool YAML in tools/active/
set -euo pipefail

name="${1:-}"
[ -z "$name" ] && { echo "usage: task add -- <name>"; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/tools/active/$name.yaml"

[ -f "$DEST" ] && { echo "exists: $DEST"; exit 1; }

cat > "$DEST" <<EOF
name: $name
binary: $name
repo: owner/$name
homepage: https://github.com/owner/$name
category: misc
tags: []
install: brew install $name
update: brew upgrade $name
check_version: $name --version | awk '{print \$2}'
github_latest: true
summary: TODO short one-liner.
help: |
  ## $name

  TODO description.

  ### Top commands
  - \`$name --help\` — show help

  ### Pitfalls
  - TODO
EOF

echo "created $DEST"
echo "next: edit fields, then 'task site'"
