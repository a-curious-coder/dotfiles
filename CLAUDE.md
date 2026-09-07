# dotfiles

Global agent rules live in `~/.claude/CLAUDE.md`. This file adds repo-specific rules.

## Branching

Personal repo, single user — commit and push directly to `main`. No branch, no PR required.

Never `git push --force` to `main`.

## Commit attribution

Commits are authored by the repo owner only. Do **not** add `Co-Authored-By:
Claude` (or any AI co-author trailer) to commit messages, and do not add
"Generated with Claude Code" footers to commits or PR bodies.

This overrides the harness default that appends those trailers.
