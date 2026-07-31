# Herdr plugins

This document tells you how to use each herdr plugin on this machine. It
follows Simplified Technical English (ASD-STE100). Sentences are short.
Sentences give one instruction or one fact. Words repeat on purpose.

Config file: `~/.config/herdr/config.toml` (this repo:
`herdr/.config/herdr/config.toml`).

To see all installed plugins, run this command:

```
herdr plugin list
```

Note: `unit1.claude-usage` (Claude Usage) was installed, then removed.
herdr's own built-in display already shows Claude usage. The plugin's
sidebar row was a duplicate of that.

## flock.farm — Flock

Source: `github:ragamo/herdr-flock`

### Purpose

This plugin shows your AI agents as pixel-art sheep. The sheep live on a
farm. This plugin has no work purpose. It is for enjoyment only.

### How to use it

1. Press `prefix+i`.
2. The Flock Farm pane opens.
3. Look at your agents as sheep.

No further setup is needed.

## triage — Herdr Triage

Source: `github:natori-hrj/herdr-triage`

### Purpose

This plugin lists your agents in order of urgency. It puts the agent that
has waited the longest at the top. Use this plugin to answer one question
fast: "which agent do I deal with first?"

### How to use it

1. Press `prefix+a`.
2. A pane opens. The pane lists your agents.
3. Read the list from the top. The top agent has waited the longest.
4. Go to that agent first.

The list updates on its own. You do not need to refresh it.

### Setup notes

No setup step is required. The plugin only reads agent status. It does not
run commands and it does not change files.

## tdi.worktree-setup — Worktree Setup

Source: `github:tdi/herdr-worktree-setup`

### Purpose

This plugin prepares a new git worktree for you. It runs when herdr creates
a worktree. You do not start it by hand.

### What it does on this machine

This plugin has two step lists. It picks one list for each new worktree.

- The `[default]` list. This list runs for any repo with no list of its
  own.
- A `[[project]]` list. This list runs only for the repo it names. This
  machine has one `[[project]]` list, for `nourish-organisations`. A repo
  with its own list does NOT also run the `[default]` list.

**The `[default]` list does three steps, in order:**

1. It copies `.env` from the main repo into the new worktree, if `.env`
   exists.
2. It runs `mise trust` in the new worktree.
3. It runs `direnv allow` in the new worktree, if `direnv` is installed.

**The `nourish-organisations` list does more.** This repo keeps some
local-only files outside the repo, in `~/dotfiles/nourish-organisations`
(a separate, git-tracked folder, not part of this dotfiles repo). A
symlink puts each file back into the repo. A new worktree starts with
none of these symlinks. So this repo's list does these steps, in order:

1. It links `bin/dev` into the new worktree.
2. It links `bin/refresh` into the new worktree.
3. It links `bin/local-setup` into the new worktree.
4. It links `CLAUDE.local.md` into the new worktree.
5. It links `mise.toml` into the new worktree. This step must run before
   step 6, or `mise trust` has no file to trust.
6. It copies `.envrc` from the main repo into the new worktree, if
   `.envrc` exists.
7. It runs `mise trust` in the new worktree.
8. It runs `direnv allow` in the new worktree, if `direnv` is installed.

This list does NOT run `bundle install`, `yarn install`, or a database
step. Most worktrees hold file edits only. They never run the app. Run
`bin/refresh` by hand, only in the one worktree you plan to run the app
in. See "Are worktrees practical for nourish-organisations?" further down
this file for why.

If any step fails, the plugin stops. It does not run the steps after the
failed step. Every step above ends in `|| true`, on purpose. This means
one step's failure does not stop the rest.

### How to use it

1. Create a worktree the normal way (`prefix+shift+o`, or your usual git
   worktree command).
2. Do nothing else. The plugin runs on its own.
3. If you want to check what ran, open this log file:
   `$HERDR_PLUGIN_STATE_DIR/setup-<timestamp>.log`

### Setup notes

The step lists live here:
`~/.config/herdr/plugins/config/tdi.worktree-setup/config.toml`

Edit this file to add or remove steps. Steps run under the `[default]`
table. Add a `[[project]]` table to give one repo its own step list. A
repo's `path` value must match its MAIN checkout path, not a worktree
path.

#### The `link.sh` tool

`~/dotfiles/link.sh` links one local-only file from this repo into one
project. This tool works for any project folder under `~/dotfiles`, not
only `nourish-organisations`. This tool also works for a worktree, not
only the main checkout.

```
~/dotfiles/link.sh <project> <path> [target-repo]
```

- `<project>` — a folder under `~/dotfiles`. Example:
  `nourish-organisations`.
- `<path>` — the file's path inside that project. Example: `bin/dev`.
- `[target-repo]` — where to put the symlink. Optional. Default:
  `~/Projects/work/<project>`. Give a worktree path here to set up that
  worktree by hand.

`~/dotfiles/nourish-organisations/link.sh` still works the old way, with
one argument (`./link.sh bin/dev`). It now also takes a second argument,
for a worktree path (`./link.sh bin/dev /path/to/worktree`).

### Are worktrees practical for nourish-organisations?

Short answer: yes, for file edits. The Postgres and Redis containers for
this repo are already fixed, shared containers — they exist once, no
matter how many worktrees exist. Ruby gems install to one shared folder
outside any repo, so a new worktree costs almost no extra disk for gems.
`node_modules` is the one real cost: about 2.4GB per worktree, since this
repo's Yarn setup makes real files, not links. Only run one full app
runtime (`bin/dev`) at a time. Use other worktrees for file edits only,
and run `bin/refresh` in a worktree only when you are about to make it
the one active runtime.

## vim-herdr-navigation — Vim Herdr Navigation

Source: `github:paulbkim-dev/vim-herdr-navigation`

### Purpose

This plugin lets you move between Neovim splits and herdr panes with one
set of keys. You do not need one key set for Neovim and a different key
set for herdr.

### How to use it

1. Press `ctrl+h`, `ctrl+j`, `ctrl+k`, or `ctrl+l`.
2. If Neovim has a split in that direction, focus moves to that split.
3. If Neovim is at the edge of its splits, focus moves to the next herdr
   pane in that direction.
4. The same four keys also move focus between herdr panes when you are not
   in Neovim.

### Setup notes on this machine

This machine also uses a different plugin, `nvim-tmux-navigation`, for the
same keys inside tmux. To keep both working, this repo does not use the
file that vim-herdr-navigation suggests
(`editor/nvim.lua`). Instead, this repo uses its own file:

`nvim/.config/nvim/lua/herdr-nav.lua`

This file does one of two things, in order:

1. Inside a herdr pane: it crosses into the next herdr pane at a split
   edge.
2. Outside herdr (for example, plain tmux): it calls the existing
   `nvim-tmux-navigation` plugin. Tmux navigation works the same as before.

You do not need to do anything more. This file loads on Neovim startup.

Caveat: binding `ctrl+l` and `ctrl+k` this way can block your shell's own
`ctrl+l` (clear screen) and `ctrl+k` (delete to end of line) inside plain
shell panes. This is a known trade-off, not a bug.

## herdr-keys — herdr-keys

Source: `github:JacquesvanWyk/herdr-keys`

### Purpose

This plugin shows a list of your keybindings. It reads them from herdr,
Neovim, tmux, and other config files. Use this plugin when you forget a
key.

### How to use it

1. Press `prefix+y` to open the list in a split pane.
2. Or press `ctrl+alt+y` to open the list in a new tab.
3. Type to filter the list.
4. Press `Enter` on a keybinding to see its detail.
5. Press `ctrl-y` to copy a keybinding.
6. Press `ctrl-e` to open the config file for a keybinding.
7. Press `ctrl-f` to mark a keybinding as a favorite.
8. Press `ctrl-r` to scan for new keybindings.
9. Press `Esc` to go back or close the pane.

### Setup notes

No setup step is required. To add your own personal notes about a key, add
them to this file: `~/.config/herdr/plugins/config/herdr-keys/personal.tsv`

## claude-auto-retry — Claude Auto Retry

Source: `github:mo-arvan/herdr-claude-auto-retry`

### Purpose

This plugin waits for you when Claude Code hits a rate limit. When the
rate limit clears, the plugin resumes Claude Code on its own. You do not
need to watch the pane and retry by hand.

### How to use it

Do nothing. This plugin works on its own, in the background, once it is
watching a pane.

This machine ran this setup command once:

```
herdr plugin action invoke claude-auto-retry.watch-all
```

This command attached the plugin to every open Claude Code pane. New
Claude Code panes are picked up on their own after this. You do not need
to run the command again.

### Other commands, if you need them

- `herdr plugin action invoke claude-auto-retry.status` — show which panes
  the plugin is watching.
- `herdr plugin action invoke claude-auto-retry.arm` — watch only the
  pane you are focused on.
- `herdr plugin action invoke claude-auto-retry.stop` — stop watching all
  panes.
- `herdr plugin action invoke claude-auto-retry.logs` — show the plugin's
  log.

### Caveat

The plugin only acts when herdr reports that a pane has stopped. It does
not act while Claude Code is still working. If Claude Code is not in a
resumable state right when the rate limit clears, the plugin's auto-typed
message may not land. This is rare.

## gh-pr — GitHub PR Status

Source: `github:wyattjoh/herdr-plugin-gh-pr`

### Purpose

This plugin shows the pull request status for the branch in your focused
pane. It shows this status as a small label in the sidebar, for example
`#123 ✓`.

### Label icons

- `✓` — checks passed
- `✗` — checks failed
- `●` — checks running
- `◆` — review requested or changes requested
- `⊘` — no pull request found
- `⟳` — the plugin is refreshing the status now

### How to use it

1. Look at the sidebar row for a pane. If the pane's branch has a pull
   request, you see a label like `#123 ✓`.
2. To open that pull request in your browser, focus the pane and press
   `prefix+o`.
3. To force a refresh now, press `prefix+shift+g`. (The label also
   refreshes on its own, but at most once every 30 seconds.)

### Setup notes

Setup is already done on this machine:

- The sidebar row is turned on in `config.toml`, under
  `[ui.sidebar.agents]`.
- This plugin needs `gh` (the GitHub CLI) signed in. Check sign-in with:
  `gh auth status`
- This plugin needs `bun`. `bun` was installed with `mise`.

#### Known gotcha: herdr cannot see `mise`-installed tools by default

herdr runs plugin commands with a minimal `PATH`. This `PATH` does not
include mise's shim folder. This means a command like `bun`, installed
only through `mise`, is not found, even though it works in your normal
terminal.

Symptom: every action log for this plugin shows this error:
`No such file or directory (os error 2)`

Fix used on this machine: a symlink was added so `bun` is on the `PATH`
that herdr does use.

```
ln -s "$(mise which bun)" /opt/homebrew/bin/bun
```

`/opt/homebrew/bin` was picked because the `herdr` program itself already
runs from that folder. If a future plugin needs another `mise`-only tool,
use the same fix: symlink that tool into `/opt/homebrew/bin`.

## structupath.guard — Guard

Source: `github:StructuPath/herdr-guard`

### Purpose

This plugin watches the commands your agents type. It checks each command
against a list of rules. If a command matches a dangerous rule, the plugin
can stop the command before it runs. Use this plugin as a safety net for
autonomous agents.

### Rule severities

- `audit` — the plugin records the command. It does not warn you.
- `alert` — the plugin warns you. The command still runs.
- `interrupt` — the plugin tries to cancel the command before it runs.

### Default rules on this machine

These commands are set to `interrupt` (the plugin tries to stop them):

- `rm -rf` on a root-level or home path
- `dd` writing to a device
- `mkfs` (format a filesystem)
- `terraform destroy`
- `kubectl delete` against a production-looking context, or with `--all`

These commands are set to `alert` (the plugin warns you, but does not stop
them):

- `git push --force`
- `git reset --hard`
- `sudo` commands
- `curl | sh` style pipelines

### How to use it

1. The plugin's dashboard pane opens on its own when herdr starts.
2. If a command is stopped, look at the dashboard pane for the reason.
3. To pause the plugin for 15 minutes, run:
   `herdr plugin action invoke pause --plugin structupath.guard`
4. To turn the plugin back on, run:
   `herdr plugin action invoke resume --plugin structupath.guard`
5. To test a command against the rules without running it, run:
   `herdr plugin action invoke test --plugin structupath.guard`

### Setup notes

The rule file is here:
`~/.config/herdr/plugins/config/structupath.guard/rules.json`

Edit this file to add, remove, or change rules.

### Caveat — read this before you rely on this plugin

This plugin checks text. It does not check intent. It has these known
gaps:

- It does not see commands typed into a raw or no-echo shell.
- It does not see commands typed into a herdr popup pane (version 1).
- It cannot help if its own pane is closed or the plugin is disabled.
- It runs with your own user permissions. It is not a sandbox.

Check the default rules yourself before you trust this plugin with
high-risk work.

## New keybindings added for this setup

| Key | Plugin | Action |
| --- | --- | --- |
| `ctrl+h` / `ctrl+j` / `ctrl+k` / `ctrl+l` | vim-herdr-navigation | move focus left / down / up / right |
| `prefix+y` | herdr-keys | open keybinding cheatsheet (split pane) |
| `ctrl+alt+y` | herdr-keys | open keybinding cheatsheet (tab) |
| `prefix+a` | triage | open agent attention list |
| `prefix+o` | gh-pr | open focused pane's pull request |
| `prefix+shift+g` | gh-pr | force-refresh pull request status |

`prefix+i` still opens Flock Farm. It has not changed.
