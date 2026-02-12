# Repo Refinement Checklist

> Living document: update the **Progress Snapshot** section whenever work is completed or scope changes.

## Progress Snapshot

- Date: 2026-02-12
- Status: active
- Recent completed milestones:
  - [x] Baseline snapshot commit (excluding `git/`)
  - [x] Neovim clarity pass (`templates`, `telescope`, keymaps)
  - [x] tmux one-command bootstrap (`setup-tmux.sh`)
  - [x] Ignore `git/` and stop tracking `git/.gitconfig`
  - [x] Shell/install cleanup pass (`zsh/.zshrc`, `install-modern-tools.sh`)
  - [x] Added `bootstrap.sh` orchestrator (tools + stow + tmux bootstrap)
  - [x] Added lightweight CI checks (`shellcheck` + Neovim text-specs)
  - [x] Removed unused CTF/security shell surface and guide docs
- In-flight (not committed):
  - [ ] Telescope recent-files fix in `nvim/.config/nvim/lua/plugins/telescope.lua`

## Principles (Guardrails)

- [ ] YAGNI: no features without a current pain point
- [ ] KISS: prefer direct scripts/config over abstractions
- [ ] DRY: only extract when duplication is real and recurring

## High-Impact Next Steps

- [x] Add `bootstrap.sh` (single entrypoint)
  - Goal: run minimal setup in one command
  - Scope: call existing scripts (`install-modern-tools.sh`, `setup-tmux.sh`, stow common + platform packages)
  - Constraint: orchestrate only; do not duplicate installer logic

- [x] Add lightweight CI checks
  - Goal: prevent regressions and drift
  - Scope: `shellcheck` for maintained repo shell scripts, Neovim text-spec scripts in `nvim/.config/nvim/tests`
  - Constraint: fast checks only (no heavy environment setup)

- [x] Trim optional shell surface area
  - Goal: reduce default complexity in daily shell startup
  - Scope: remove unused CTF/security aliases/functions/docs from active setup
  - Constraint: no unrelated shell behavior changes

- [ ] Rationalize large imported theme/config bundles
  - Goal: make active defaults obvious
  - Scope: separate actively used configs from archived/vendor variants
  - Constraint: no mass rewrites; move in small, reversible steps

## Nice-to-Have (Later)

- [ ] Add `docs/operations.md` with 5-10 common commands (stow, unstow, tmux bootstrap, calibre checks)
- [ ] Add a small script for dead-link checks in markdown docs

## Definition of Done (for each checklist item)

- [ ] Change is explainable in 2-3 sentences
- [ ] No new unnecessary abstraction introduced
- [ ] Relevant script/lint/test check passes
- [ ] This document’s **Progress Snapshot** is updated
