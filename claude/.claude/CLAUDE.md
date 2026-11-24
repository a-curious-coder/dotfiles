# Global Claude Code preferences

## Session boundaries
- Cap concurrent agents/subagents/forks at 5. If asked for more, say so and ask which to drop.
- After 11:00 PM local time, before starting new agent-driven work (not a quick question), ask Callum to confirm he wants to keep going.
- Reason: unbounded agent fan-out at night ("AI vampire") trades sleep for throughput. These two rules interrupt that before it starts; they are not meant to slow daytime work.
- Delegate separable grunt work (broad searches, bulk reads, filtering data) to subagents. They run on Sonnet by default; keep judgment and the final answer in the main session.

## Responsible AI usage
- Never send customer, patient, or proprietary data, or secrets, to a tool or service the organisation has not approved (web search, external APIs, pastebins).
- Never open PRs, issues, or comments on any external service unless Callum says to in that instance.
- Two-retry cap: if the same approach fails twice, stop. Name the assumption that might be wrong before trying again.
- Strict mode for customer-facing work is the `careful` skill; `prep-card` turns it on.

## Skill routing
Callum only starts `/prep-card` himself. When one of these moments appears, name the one skill in one line and ask before running it:
- Asks what to work on → `next-card`. Starts a Jira card → `prep-card`.
- An agreed plan exists → `implement-plan`. Changes exist but careful was off → `careful-check`.
- About to commit or open a PR → `teach-back`, then `code-review`.
- Its AI review came back clean → `ready-for-review`.
- After a substantive explanation or fix → `knowledge-check`. Free time with no card → `study`.

## Git
- Never run `git commit` or `git push` (including new branches) unless Callum says so in that instance. Staging and preparing a diff is fine.
- When asking to commit, show `git diff --stat` and the key hunks.
- No `Co-Authored-By` trailer.
- One branch at a time. A fix unrelated to the current branch stays on it: no second branch, never a worktree. Mention it in the report.

## Shell
- Use `rg` not `grep` and `fd` not `find`, everywhere, including mid-pipe. Prefer the harness Grep/Glob tools when present. `fd` skips gitignored and hidden files; add `-H -I` for a full sweep.
- `cd` is zoxide, also in agent shells: a missing path jumps to a remembered directory instead of failing. Pass absolute paths and prefer a tool's own path argument.

## Replies
- ADHD mode and ponytail both claim the last line. The last line is the next action; what was skipped and any risk go on the line before it.
- When structure matters (architecture, flows, before/after), show a diagram or an HTML page instead of long prose. Prose explanations follow ASD-STE100.

## Action log
After work that changes something (file edits, installs, system config, commits), silently append one entry per distinct action to `~/.claude/logs/<YYYY-MM-DD>.md`. Skip read-only sessions.

```
### HH:MM | <specific action title>
**Did:** <one line: exactly what changed and where>
**Why:** <one line: reason for this action>
```

## Obsidian vault (`~/Desktop/the-vault`)
- Read `Vault style guide.md` at the vault root before writing or editing a note.
- Engineering-judgment calls (code shape, comments, review, PR communication): consult the hub note "Engineering taste comes from corrected mistakes, not abstract rules.md". Add a new child note there, not here, when a correction or confirmation happens on a project.
- Recipes: when mid-task you hit a named process you had no context on, and working it out took real effort (not one grep or file read), save it as a vault note, not in the memory dir. Skip anything derivable on demand.
  - Evergreen note in the vault root; title is a full statement ("Rotate staging DB credentials without downtime").
  - Frontmatter: `categories: ["[[Guides]]"]`, `topics:` for the system, `tags: [ai-drafted]` (mandatory), `source:` a wikilink to what triggered it.
  - Body in ASD-STE100: short sentences, one instruction each, active voice.
  - Never remove `ai-drafted`; only Callum does, after verifying.

## Issue tracking: `sd` (seeds)
- `sd` is the tracker for every project; use it instead of markdown TODO files.
- Run `sd prime` at session start and after compaction for the command reference; do not guess flags. No `.seeds/` → `sd init` first.
- `sd sync` commits, so the Git rule applies: ask first.
- Within-turn checklists stay in the harness task tool. Anything outliving the session goes in `sd`.
- Do not file an issue for a straightforward task (one tag, one link); name it in one line instead.
