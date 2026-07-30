# dotfiles

Global agent rules live in `~/.claude/CLAUDE.md`. This file adds repo-specific rules.

## Branching

`main` is protected by convention: **do not commit or push new work directly to it.**

1. Branch first: `git switch -c <type>/<short-description>` (`feat/`, `fix/`, `chore/`, `docs/`).
2. Commit on the branch, push with `git push -u origin <branch>`.
3. Open a PR (`gh pr create`) and wait for review.
4. Merge with `gh pr merge --squash --delete-branch` — squash only, one commit per PR on `main`.

Exceptions, no branch needed:

- Commits already on local `main` as of 2026-07-30 (the pre-rule backlog) — push those directly.
- Nothing else. If a change feels too small for a PR, it still gets a branch.

Never `git push --force` to `main`.

## Commit attribution

Commits are authored by the repo owner only. Do **not** add `Co-Authored-By:
Claude` (or any AI co-author trailer) to commit messages, and do not add
"Generated with Claude Code" footers to commits or PR bodies.

This overrides the harness default that appends those trailers.
