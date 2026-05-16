#!/usr/bin/env python3
"""YAML manifests → static HTML site (kapi-brand)."""
from __future__ import annotations

import json
import shutil
from collections import defaultdict
from datetime import date
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader, select_autoescape
from markdown import markdown

ROOT = Path(__file__).resolve().parent.parent
ACTIVE = ROOT / "tools" / "active"
DISCARDED = ROOT / "tools" / "discarded"
TEMPLATES = ROOT / "templates"
SITE = ROOT / "site"
CACHE = ROOT / "cache" / "versions.json"


def load_yaml_dir(path: Path) -> list[dict]:
    items = []
    for f in sorted(path.glob("*.yaml")):
        with f.open() as fh:
            data = yaml.safe_load(fh) or {}
        data["_slug"] = f.stem
        items.append(data)
    return items


def load_versions() -> dict:
    if not CACHE.exists():
        return {}
    with CACHE.open() as fh:
        return json.load(fh)


def enrich(tool: dict, versions: dict) -> dict:
    info = versions.get(tool["name"], {})
    tool["local_version"] = info.get("local")
    tool["latest_version"] = info.get("latest")
    tool["checked_at"] = info.get("checked_at")
    if tool["local_version"] and tool["latest_version"]:
        tool["status"] = "ok" if tool["local_version"] == tool["latest_version"] else "update"
    else:
        tool["status"] = "unknown"
    tool["help_html"] = markdown(tool.get("help", ""), extensions=["fenced_code", "tables"])
    return tool


def main() -> None:
    SITE.mkdir(exist_ok=True)
    (SITE / "tool").mkdir(exist_ok=True)

    env = Environment(
        loader=FileSystemLoader(TEMPLATES),
        autoescape=select_autoescape(["html"]),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    versions = load_versions()
    active = [enrich(t, versions) for t in load_yaml_dir(ACTIVE)]
    discarded = load_yaml_dir(DISCARDED)

    categories: dict[str, list[dict]] = defaultdict(list)
    for t in active:
        categories[t.get("category", "misc")].append(t)

    all_tags = sorted({tag for t in active for tag in t.get("tags", []) or []})

    today = date.today().isoformat()

    # index
    (SITE / "index.html").write_text(
        env.get_template("index.html").render(
            tools=active,
            categories=dict(sorted(categories.items())),
            tags=all_tags,
            count_active=len(active),
            count_discarded=len(discarded),
            today=today,
        )
    )

    # per-tool
    for t in active:
        out = SITE / "tool" / f"{t['_slug']}.html"
        out.write_text(env.get_template("tool.html").render(tool=t, today=today))

    # discarded
    (SITE / "discarded.html").write_text(
        env.get_template("discarded.html").render(tools=discarded, today=today)
    )

    # copy static assets
    static_src = TEMPLATES / "static"
    if static_src.exists():
        dst = SITE / "static"
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(static_src, dst)

    print(f"built {len(active)} active + {len(discarded)} discarded → {SITE}")


if __name__ == "__main__":
    main()
