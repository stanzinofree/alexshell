# alexshell

Curated personal CLI tool index. YAML manifests → searchable HTML site + tmux/fzf launcher + update checker.

## Layout

```
tools/active/<name>.yaml      # curated tool
tools/discarded/<name>.yaml   # parked, recheck_after date
templates/                    # Jinja2 HTML templates (kapi-brand)
site/                         # generated HTML (GitHub Pages)
scripts/build_site.py         # YAML → HTML
scripts/check_updates.py      # query GitHub releases, write cache/versions.json
scripts/launch.sh             # tmux 3-pane + fzf
Taskfile.yml                  # task add | check | update | site | launch | recheck
```

## Workflow

1. Session with Claude: pick tool, extract docs → write `tools/active/<name>.yaml`
2. `task site` → regen HTML
3. `task check` → table of available updates
4. `task launch` → tmux session (shell | fzf list | help viewer)
5. Discard underwhelming tools to `tools/discarded/` with `recheck_after` date
6. `task recheck` → list discarded tools past recheck date

## Add tool

```sh
task add -- <name>
# edit tools/active/<name>.yaml
task site
```

## Site

GitHub Pages: nightly Action runs `check_updates.py`, commits `cache/versions.json`, rebuilds site.

Made with <3 by Alessandro
