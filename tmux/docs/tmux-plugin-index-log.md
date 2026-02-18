# TMUX Plugin Index Log

This file tracks plugin additions/removals against the curated upstream index:

- Curated index: https://github.com/tmux-plugins/list
- Last reviewed: 2026-02-18
- Review cadence: monthly, or before any plugin add/remove.

## Decision Rules (Inferred)

Inferred from Steph Ango's published principles as Obsidian CEO:

- Prefer durable primitives over magic: plugin must not hide core tmux behavior.
- Keep default surface area minimal: no always-on UI clutter without clear signal.
- Prefer composable tools: one plugin should solve one workflow cleanly.
- Favor local control and reversibility: easy to remove, no data lock-in behavior.
- Avoid complexity debt: if a plugin duplicates existing config, remove it.

References:

- https://stephango.com/about
- https://stephango.com/file-over-app
- https://stephango.com/vault

## Current Decisions

### Keep

- `tmux-plugins/tpm`
  - Required plugin manager.
- `tmux-plugins/tmux-resurrect`
  - Durable session restore with explicit value.
- `tmux-plugins/tmux-continuum`
  - Auto-save/restore is high-value for continuity.
- `sainnhe/tmux-fzf` (added on 2026-02-18)
  - Single command-palette style control surface for sessions/windows/panes.
  - Constrained to high-signal actions via `TMUX_FZF_ORDER`.
- `alexwforsythe/tmux-which-key` (added on 2026-02-18)
  - Discoverable keybinding UI popup for mnemonic navigation.
  - Set as primary binding help UX on `prefix + ?`.
- `niqodea/tmux-matryoshka` (added on 2026-02-18)
  - Nested tmux control only, no always-on status clutter.
- `fcsonline/tmux-thumbs` (added on 2026-02-18)
  - Fast in-pane hint picking for links/paths/identifiers.

### Remove

- `tmux-plugins/tmux-sensible` (removed on 2026-02-18)
  - Redundant with explicit local config; adds hidden defaults.

### Watchlist (Not Installed)

- `tmux-plugins/tmux-sessionist`
  - Consider only if native/sessionx/session switching starts to feel insufficient.

## Review Template

Use this format for future updates:

```md
## Review YYYY-MM-DD
- Added:
- Removed:
- Deferred:
- Rationale:
```

## Review 2026-02-18
- Added:
  - `sainnhe/tmux-fzf`
  - `alexwforsythe/tmux-which-key`
  - `niqodea/tmux-matryoshka`
  - `fcsonline/tmux-thumbs`
- Removed:
- Deferred:
  - `tmux-plugins/tmux-sessionist` (only if we need extra session commands beyond current flow)
- Rationale:
  - Add high-leverage interaction tools while keeping always-visible UI minimal.
  - Keep plugin scope explicit via keybinds and option constraints.
