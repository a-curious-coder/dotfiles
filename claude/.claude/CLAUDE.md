# Global Claude Code preferences

## Session boundaries (agent workload health)
Cap concurrent agents/subagents/forks at 5 at any one time — do not spawn a 6th until one finishes. If asked to run more, say so and ask which to drop instead of silently scaling up.
After 11:00 PM local time, before starting any new agent-driven work (not a quick question), ask Callum to confirm he wants to keep going rather than assuming yes.
Reason: unbounded agent fan-out at night is the specific pattern ("AI vampire") that trades sleep for throughput. The cap and the time check exist to interrupt that escalation before it starts, not to slow down daytime work.

## Responsible AI usage (always on)
- Never send customer, patient, or proprietary data, or secrets, to a tool or service the organisation has not approved (web search, external APIs, pastebins).
- Never open PRs, issues, or comments on any external service unless Callum says to in that instance.
- When asking to commit, show `git diff --stat` and the key hunks so Callum can skim the diff first.
- Two-retry cap: if the same approach fails twice, stop. Name the assumption that might be wrong before trying again.
Strict mode for customer-facing work is the `careful` skill (`/careful`); `prep-card` turns it on. Source: `~/Projects/personal/x-ai-opinions/distilled.md`.

## Skill routing
Callum should not need to remember skill names; the only one he starts himself is `/prep-card`. When one of these moments appears, name the skill in one line and ask before running it. Suggest one skill at a time, never a list.
- Asks what to work on → `next-card`. Starts a Jira card → `prep-card`.
- An agreed plan exists → `implement-plan`. Changes exist but careful was off → `careful-check`.
- About to commit or open a PR → `teach-back`, then `code-review`.
- Its AI review came back clean → `ready-for-review`.
- After a substantive explanation or fix → `knowledge-check`. Free time with no card → `study`.

## Git commits and pushes require explicit permission
Never run `git commit` or `git push` (including creating/pushing new branches) unless the user has explicitly told you to do so in that instance. Staging changes and preparing a diff is fine; committing or pushing is not, even for small, unrelated, or "obviously safe" fixes. Always stop and ask before committing or pushing.

## Git commits
Do not add a `Co-Authored-By` trailer to commit messages.

## Unrelated fixes found while on a feature branch

Work on one branch at a time. If you make a fix unrelated to the current feature
branch, keep it on that branch — do not create a second branch for it, and never
create a git worktree. Mention the unrelated change when you report back so it
can be reviewed as part of the same diff.

## Shell tools

Use `rg` not `grep` and `fd` not `find`, everywhere, including mid-pipe. If the
harness has Grep or Glob tools, prefer them. `fd` skips gitignored and hidden
files; add `-H -I` for a full sweep.

## Reply endings

ADHD mode and ponytail both claim the last line. The last line is the next
action. Put what was skipped and any risk on the line before it.

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

## Obsidian vault

Vault root: `~/Desktop/the-vault`. Before writing or editing a note there, read
`Vault style guide.md` at the vault root.

## Engineering taste (Obsidian vault)

Callum's engineering-judgment calls — not session mechanics, those live above
in this file — are collected in the vault, starting from the hub note
"Engineering taste comes from corrected mistakes, not abstract rules.md"
(vault root). It links out to one evergreen note per principle, each with the
incident that produced it. Consult it for code-shape, comment, review, and
PR-communication judgment calls; add a new child note there (not here) when a
new correction or confirmation happens on a project.

## Recipe notes (Obsidian vault, not the local memory dir)

A recipe records a named process or workflow (e.g. "run process X", "the Y release
flow") that you had to leave the current task to go figure out, with no context
otherwise available. Recipes do not go in the per-project memory dir — they go in the
Obsidian vault (path above), so Callum's
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

## Issue tracking: use `sd` (seeds)

`sd` (`@os-eco/seeds-cli`, git-native issue tracker) is the issue tracker for every
project. Use it instead of markdown TODO files or ad-hoc issue lists.

- Run `sd prime` at the start of a session (and after compaction) to load the full
  command reference — do not guess flags from memory.
- `sd ready` to find work, `sd create --title="..." --type=task --priority=2` to file,
  `sd update <id> --status=in_progress` to claim, `sd close <id>` when done.
- If a repo has no `.seeds/`, run `sd init` before filing anything.
- `sd sync` stages and commits `.seeds/` — it is a `git commit`, so the
  "commits require explicit permission" rule above applies. Ask first.
- Session task checklists (the harness task tool) are still fine for
  within-turn progress. Anything outliving the session goes in `sd`.
- Exception: do not file or suggest an `sd` issue for a straightforward task
  (e.g. "drag two notes", "check one tag", "fix one link"). Name it in one line
  in the reply instead. `sd` is for work that needs a plan or spans sessions.
  Reason: filing trivial follow-ups adds tracking overhead with no benefit.

## Orchestration
Act as an orchestrator. Spawn teammates when a task needs one, reuse
existing teammates where they fit, and shut them down when their work
is finished.
