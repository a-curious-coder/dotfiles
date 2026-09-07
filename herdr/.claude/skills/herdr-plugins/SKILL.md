---
name: herdr-plugins
description: Audit herdr terminal-multiplexer plugins against the live public registry (assets.herdr.dev) — find installed plugins with newer/more-popular replacements, redundant overlapping plugins, and highly-starred plugins not yet installed. Use when the user wants to review, curate, or discover herdr plugins, or asks "what herdr plugins should I add/remove", "check for better herdr plugins", or similar. Scoped to herdr/ dotfiles.
---

# herdr-plugins

## What this does

herdr's plugin registry (`https://assets.herdr.dev/plugins/index.json`) is a
live GitHub-topic-scraped index (~1000 repos tagged `herdr-plugin`), with
stars/forks/description per plugin. It changes daily as new plugins ship.
There's no installed-vs-registry diff built into herdr itself, so this skill
provides one.

## Step 1: Run the audit script

```
sh /Users/callummclennan/Projects/personal/dotfiles/herdr/.claude/skills/herdr-plugins/audit.sh [top-n]
```

This fetches the current registry, prints the top N plugins by star count
(default 40), then lists every currently-installed plugin
(`~/.config/herdr/plugins.json`) with its live registry star count.

## Step 2: Look for three things

1. **Redundant plugins we have** — two installed plugins doing overlapping
   jobs (e.g. a usage/quota plugin whose feature is a subset of another
   already-installed plugin's). Flag, don't remove — ask which to drop.
2. **Better replacements** — an installed plugin has a much more-starred or
   more-capable alternative in the registry doing the same job. Cross-check
   with `rg -i "<keyword>"` against the full registry dump
   (`jq -r '.plugins[] | ...'` on the cached JSON) before recommending a
   swap — star count alone isn't capability.
3. **Gaps worth filling** — high-star registry plugins with no installed
   counterpart, relevant to this user's actual workflow (git/worktree/agent
   monitoring/tmux-like navigation — see `herdr/.config/herdr/config.toml`
   for what's already bound to keys).

## Step 3: Report, don't auto-install

Installing/uninstalling herdr plugins changes the running system
(`herdr plugin install/uninstall`, or editing `~/.config/herdr/plugins.json`
and `config.toml` keybinds together). Present findings as a short ranked list
(recommendation first) and let the user choose — this mirrors the repo's
"confirm before changing shared/running state" norm even though this repo
allows direct-to-main commits.
