# Global Claude Code preferences

## Git commits and pushes require explicit permission
Never run `git commit` or `git push` (including creating/pushing new branches) unless the user has explicitly told you to do so in that instance. Staging changes and preparing a diff is fine; committing or pushing is not, even for small, unrelated, or "obviously safe" fixes. Always stop and ask before committing or pushing.

## Addressing the user
The user's first name is Callum. Address him by name in every response.

## Git commits
Do not add a `Co-Authored-By` trailer to commit messages.

## Unrelated fixes found while on a feature branch
If you make a fix or do work that's unrelated to the current feature branch (e.g. a bug noticed while debugging something else), don't leave it staged/unstaged on that branch and don't commit it there either. Instead: create a new branch off `main` prefixed `INTERNAL` (e.g. `INTERNAL-fix-specificable-nil-guard`), commit the unrelated work there, then switch back to the original feature branch. Keeps feature branches clean and the unrelated fix separately reviewable/mergeable.

**Isolate the commit, not the runtime.** Use a git worktree (`git worktree add /tmp/<name> main -b INTERNAL-...`) only to get a clean `main`-based checkout to commit into — never spin up a second `bin/dev`/Docker/Rails stack for it. Running two full runtimes of the same app is expensive and pointless: Postgres/Redis are already running for the main checkout, and any test run against the worktree (`bundle exec rspec ...` from inside it) hits those same shared services fine. Remove the worktree (`git worktree remove <path>`) once the commit is made.

**Mechanics that actually work**, learned the hard way mid-session:
- Check `git checkout main`'s exit code before running `checkout -b` — if the checkout was rejected (e.g. staged changes on the current branch would be overwritten), a `checkout -b` right after it silently branches off whatever you're still on, not `main`.
- Don't extract the unrelated diff with `git stash push -- <pathspec>` + `stash pop` on the new branch. The stash still carries the full commit/index context it was taken from; popping it onto a different base (`main`) tries to 3-way-merge *everything* that differs between the two bases, not just your pathspec, and conflicts on unrelated files. Instead: `git diff stash@{0}^1 stash@{0} -- <paths> > fix.patch`, then `git apply fix.patch` in the clean worktree — a plain diff has no ancestry to reconcile.

## Shell tools

`fd` and `rg` are installed and are the preferred CLI tools on this machine.

- Searching file *contents*: use the **Grep** tool. It is ripgrep already, and it
  does not spend a Bash call. Shell out to `rg` only for flags Grep lacks.
- Finding files *by name*: use the **Glob** tool. When a shell call is genuinely
  needed, use `fd`, never `find`.
- In any Bash command, pipeline, or script: `rg` not `grep`, `fd` not `find`.
  This includes the middle of a pipe.
- `fd` skips `.gitignore`d paths and hidden files by default. Add `-H` for hidden
  and `-I` for ignored when a full sweep is the point — a bare `fd` is not a
  drop-in `find .`.

**`cd` is zoxide.** `.zshrc` runs `zoxide init zsh --cmd cd`, and this applies
inside agent shells too. `cd <name>` does frecency matching, so a path that does
not exist does not fail — it jumps to whichever remembered directory scores
highest, possibly in another project. Always pass absolute paths to Bash, and
prefer a tool's own path argument over changing directory at all.

## Action log

After completing work that makes changes (file edits, package installs, system config, git commits): silently append to `~/.claude/logs/<today's date YYYY-MM-DD>.md`. Do not announce it.

Write **one entry per distinct action** — one install, one file edit, one service enabled, etc.:

```
### HH:MM | <specific action title>
**Did:** <one line — exactly what changed and where>
**Why:** <one line — reason for this specific action>
```

Skip for read-only sessions (research, questions, explanations with no changes made).

## Recipe notes (Obsidian vault, not the local memory dir)

A recipe records a named process or workflow (e.g. "run process X", "the Y release
flow") that you had to leave the current task to go figure out, with no context
otherwise available. Recipes do not go in the per-project memory dir — they go in the
Obsidian vault, using the `access-obsidian-vault` skill to resolve its path, so Callum's
existing vault tooling (Dataview, the `ai-drafted` filter, etc.) already works on them.

**Trigger — save only when both are true:**
1. Mid-task, you hit a named process/workflow/system you have no context on.
2. Working it out took real effort (reading code, docs, or asking the user) — not
   something a single `grep` or file read would answer.

Do not save a recipe for anything derivable on demand. If future-you would not hit the
same detour, don't write it.

**Format — follow `Vault style guide.md` exactly, no separate convention:**
- Evergreen note in the vault root. Title is a full statement usable in a sentence
  (e.g. "Rotate staging DB credentials without downtime").
- Frontmatter: `categories: [[Guides]]`, `topics:` for the relevant system/tech,
  `tags: [ai-drafted]` (mandatory — this is the vault's own "LLM wrote this, unverified"
  marker, and it's what makes these notes obviously AI-authored and trivially
  include/exclude-able by anyone filtering on frontmatter), `source:` a wikilink or note
  reference to whatever triggered the recipe (a card, a project memory, a conversation).
- Body written in **ASD-STE100** (Simplified Technical English): short sentences, one
  instruction per sentence, active voice, controlled vocabulary, no idioms. Links at the
  top of the note per the style guide.
- Leave `ai-drafted` on the note. Only Callum removes it, once he's read and verified it
  — do not strip it yourself even after testing the recipe.

**Example:**
```markdown
---
categories:
  - "[[Guides]]"
topics:
  - "[[AWS]]"
tags:
  - ai-drafted
source: "[[DR-1234]]"
---
Rotate staging DB credentials without downtime.

1. Open the secrets vault. Use the `staging` namespace.
2. Generate a new credential. Do not delete the old one yet.
3. Update the app config with the new credential.
4. Redeploy the app. Confirm it connects.
5. Delete the old credential.
```
