#!/usr/bin/env python3
"""List discarded tools where recheck_after <= today."""
from __future__ import annotations

from datetime import date
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
DISCARDED = ROOT / "tools" / "discarded"


def main() -> None:
    today = date.today()
    due = []
    for f in sorted(DISCARDED.glob("*.yaml")):
        with f.open() as fh:
            t = yaml.safe_load(fh) or {}
        ra = t.get("recheck_after")
        if not ra:
            continue
        if isinstance(ra, str):
            try:
                ra = date.fromisoformat(ra)
            except ValueError:
                continue
        if ra <= today:
            due.append((t.get("name", f.stem), ra, t.get("reason", "")))

    if not due:
        print("no discarded tools due for recheck")
        return

    print(f"{len(due)} tool(s) due:")
    for name, ra, reason in due:
        print(f"  - {name}  (recheck_after={ra})  reason: {reason}")


if __name__ == "__main__":
    main()
