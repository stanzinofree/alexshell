#!/usr/bin/env python3
"""Render tool help for fzf preview / tmux pane. Usage: preview_help.py <tool_name>"""
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
ACTIVE = ROOT / "tools" / "active"


def main() -> None:
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        return
    name = sys.argv[1].strip()
    f = ACTIVE / f"{name}.yaml"
    if not f.exists():
        print(f"(no manifest: {name})")
        return
    with f.open() as fh:
        d = yaml.safe_load(fh) or {}
    print(f"# {d.get('name', name)}")
    print()
    if d.get("summary"):
        print(d["summary"])
        print()
    print(f"install: {d.get('install', '-')}")
    print(f"update:  {d.get('update', '-')}")
    print(f"check:   {d.get('check_version', '-')}")
    print(f"repo:    {d.get('repo', '-')}")
    print(f"tags:    {', '.join(d.get('tags') or [])}")
    print()
    print(d.get("help", ""))


if __name__ == "__main__":
    main()
