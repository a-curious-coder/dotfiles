# Repository Style Guide

Guidance for how this repo should evolve. Not rigid policy.

Foundation:
- [kepano-philosophy.md](kepano-philosophy.md)
- Consistent constraints, explicit tradeoffs, regular pruning.

## Core Principles

- Prefer clarity over cleverness.
- Prefer removal over addition.
- Add only for current, repeated pain.
- Accept tradeoffs; do not optimize every workflow.
- Keep configs file-based, readable, portable.
- Keep checks fast and proportional to change scope.

## Decision Filter

Before adding any tool, script, plugin, alias, or config block:

1. What specific pain does this solve today?
2. How often does that pain occur?
3. Is there a simpler change using what already exists here?
4. What ongoing maintenance does this introduce?
5. What does this make harder (startup time, complexity, portability, debugability)?
6. Can I explain this choice in 2-3 sentences in a doc or comment?
7. If this becomes unused, will I remove it quickly?

If `1-3` are weak, do not add it yet.

## Necessity Review

Use this loop for new additions:

1. Before adding:
- Write a one-line problem statement.
- Write a one-line reason alternatives are insufficient.
- Define the smallest viable change.

2. After ~30 days:
- Keep if it is used and still reduces friction.
- Simplify if partially useful.
- Remove if unused or confusing.

This repo keeps only active things. If something is no longer needed, delete it (git history is the archive).

## Area Defaults

| Area | Default | Anti-pattern |
|---|---|---|
| Shell scripts | `bash` + `set -euo pipefail`, single-purpose, orchestration over duplication | one script mixing unrelated concerns |
| Zsh config | lean startup, explicit aliases/functions for frequent tasks | niche or unused command surface in default startup |
| Neovim config | coherent keymap namespaces, plugins only for real pain, maintainable Lua | keymap sprawl and over-abstraction |
| Documentation | command-first, explain `what`/`why`/`how` for a new technical reader | hidden assumptions and prose-heavy docs |
| CI/checks | fast, local-first, script-backed checks | heavy environment setup for small config changes |
| Repo structure | active configs only, clear ownership and one obvious path | overlapping setup paths and stale bundles |

## Change Scope

- Default to small, reversible changes.
- Avoid broad rewrites unless there is repeated, demonstrated pain.
- Separate concerns so each change is easy to explain and roll back.

## Self-Review (Personal)

Before committing, quickly verify:

1. Is this solving a real current problem?
2. Is this the smallest effective change?
3. Did complexity increase, and is that increase justified?
4. Did I run appropriate checks for this change (case-by-case)?
5. Did I update docs where behavior changed?
6. Can I explain the change in 2-3 sentences?
7. Would I still add this if I had to maintain it for a year?

Optional reference: [Google Engineering Practices - Code Review](https://google.github.io/eng-practices/review/)
