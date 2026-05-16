#!/usr/bin/env python3
"""Query local version + GitHub latest release for each active tool. Write cache/versions.json."""
from __future__ import annotations

import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import requests
import yaml

ROOT = Path(__file__).resolve().parent.parent
ACTIVE = ROOT / "tools" / "active"
CACHE = ROOT / "cache" / "versions.json"

GH_TOKEN = os.environ.get("GITHUB_TOKEN")
HEADERS = {"Accept": "application/vnd.github+json"}
if GH_TOKEN:
    HEADERS["Authorization"] = f"Bearer {GH_TOKEN}"


def local_version(cmd: str | None) -> str | None:
    if not cmd:
        return None
    try:
        out = subprocess.run(
            cmd, shell=True, check=False, capture_output=True, text=True, timeout=10
        )
        v = (out.stdout or out.stderr).strip()
        return v or None
    except Exception as e:
        return f"error: {e}"


def latest_release(repo: str) -> str | None:
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        if r.status_code == 404:
            # fallback to tags
            r2 = requests.get(
                f"https://api.github.com/repos/{repo}/tags", headers=HEADERS, timeout=15
            )
            r2.raise_for_status()
            tags = r2.json()
            return tags[0]["name"] if tags else None
        r.raise_for_status()
        tag = r.json().get("tag_name", "")
        return re.sub(r"^v", "", tag) or None
    except Exception as e:
        return f"error: {e}"


def main() -> None:
    CACHE.parent.mkdir(exist_ok=True)
    out: dict[str, dict] = {}
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")

    for f in sorted(ACTIVE.glob("*.yaml")):
        with f.open() as fh:
            t = yaml.safe_load(fh) or {}
        name = t.get("name", f.stem)
        entry: dict = {"checked_at": now}
        entry["local"] = local_version(t.get("check_version"))
        if t.get("github_latest") and t.get("repo"):
            entry["latest"] = latest_release(t["repo"])
        out[name] = entry
        print(f"  {name}: local={entry.get('local')} latest={entry.get('latest')}")

    CACHE.write_text(json.dumps(out, indent=2, sort_keys=True))
    print(f"\nwrote {CACHE}")


if __name__ == "__main__":
    main()
