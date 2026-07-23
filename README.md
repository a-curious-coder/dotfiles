# Dotfiles

Personal configurations managed with GNU Stow. Plain text, portable, version-controlled.

## Purpose

This repo exists to maintain a personal, durable, low-friction development environment.

- Keep only active, necessary configuration.
- Prefer plain-text, portable files over tool lock-in.
- Make behavior easy to understand, change, and remove.

Style and decision guidance lives in [style-guide.md](style-guide.md).

## Philosophy

These configs follow [Kepano's principles](kepano-philosophy.md):

- **File over app** - Plain text configs that outlive the tools
- **Radical minimalism** - Only what serves a purpose
- **Reduced friction** - Consistent keybinds, one font stack, one color palette
- **Intentional constraints** - Start vanilla, add only when friction is unbearable
- **Clarity over cleverness** - Prefer deletion over addition; avoid abstractions unless they remove real duplication

## Structure

Each directory is a stow package. Run `stow <package>` to symlink.

```
dotfiles/
├── btop/               Resource monitor
├── calibre-linux/      Calibre config for Linux (~/.config/calibre)
├── claude/             Global Claude Code preferences (~/.claude)
├── direnv/             direnv config
├── docs/               Repo docs (operations, calibre notes, refinement checklist)
├── fastfetch/          System info (replaces neofetch)
├── ghostty/            Terminal emulator
├── git/                Git config with delta for diffs
├── herdr/              Herdr TUI config
├── hypr/               Hyprland compositor
├── kanshi/             Display profile manager for Wayland
├── lazydocker/         Docker TUI
├── lazygit/            Git TUI
├── nvim/               Neovim
├── ripgrep/            ripgrep config
├── rofi/               Application launcher
├── scripts/            Repo maintenance scripts (doctor.sh, check-shell.sh)
├── starship/           Shell prompt
├── swaync/             Notification center (Hyprland)
├── tmux/               Terminal multiplexer
├── transcription-stack/ Offline dictation daemon + voice commands (host `lp`)
├── voxtype/            Voxtype dictation config
├── waybar/             Status bar (Wayland)
├── wlogout/            Logout menu (Hyprland)
├── yazi/               Terminal file manager
└── zsh/                Shell config, aliases, functions
```

See [docs/operations.md](docs/operations.md) for common repo commands (bootstrap, stow, doctor).

## Install

```bash
git clone git@github.com:a-curious-coder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# One-command bootstrap: tools + stow + tmux plugins
./bootstrap.sh

# Or run setup steps manually:
# Symlink what you need
stow git zsh starship tmux nvim ghostty

# Optional: install modern CLI tools
./install-modern-tools.sh

# Optional: bootstrap tmux + TPM plugins
./setup-tmux.sh
```

See [SETUP.md](SETUP.md) for package installation options.

Tip: if you use zoxide, `z dotfiles` is the quickest way back to this repo.

## Platform Notes

**Linux (Hyprland)**
```bash
stow hypr kanshi waybar rofi swaync wlogout calibre-linux
```

**Common**
```bash
stow git zsh starship tmux nvim ghostty btop lazygit lazydocker fastfetch ripgrep
```

**direnv**

The zsh config initializes `direnv` after `zoxide`, so project `.envrc` files
load automatically on `cd`.

After creating or changing a project's `.envrc`, run this once from the
project:

```bash
direnv allow
```

For `nourish-organisations`, direnv is required so Rails uses the Docker
Postgres host and repo-pinned `pg_dump`. A loaded shell should show:

```bash
which pg_dump
echo "$EXPECTED_PG_DUMP_VERSION"
```

```text
/opt/homebrew/opt/postgresql@16.10/bin/pg_dump
16.10
```

**Calibre (auto-select package by OS)**
```bash
# One command: stow + apply reader style + validate
./calibre.sh

# Optional explicit subcommands
./calibre.sh stow
./calibre.sh apply
./calibre.sh check
./calibre.sh where
```

## Scripts

| File | Purpose |
|------|---------|
| `packages.yaml` | Package catalog/reference (not currently consumed by setup scripts) |
| `calibre.sh` | Single Calibre entrypoint (`stow`, `apply`, `check`, `where`, `all`) |
| `bootstrap.sh` | Orchestrate install + stow + tmux bootstrap in one command |
| `install-modern-tools.sh` | Install CLI tools (glow, mise, dust, navi, posting, etc.) |
| `setup-tmux.sh` | Stow tmux config, install/update TPM, and install plugins |
| `ubuntu_install.sh` | Compatibility wrapper that delegates to `install-modern-tools.sh` |
| `scripts/doctor.sh` | Run the main repo health checks in one go |
| `scripts/check-shell.sh` | Run `shellcheck` for maintained repo shell scripts |
| `scripts/run-nvim-text-specs.sh` | Run lightweight Neovim text-spec checks |

Docs:
- `docs/calibre.md` (Calibre profile and validation)
- `docs/operations.md` (common repo workflows and commands)

## Neovim

The nvim config has its own documentation:

- `nvim/.config/nvim/README.md` - Full documentation
- Requires: Neovim >= 0.11, Node.js, ripgrep, fd, Nerd Font
- Keymap convention: find/search on `<leader>f*`, UI toggles on `<leader>u*`
- Markdown workflow: `gf` follows `[[wikilinks]]` (including `[[note#heading]]`)
- Markdown reading: `<leader>um` toggles read view, `<leader>uM` opens split preview
- Terminal: `<leader>tt` toggles a floating terminal
- Autosave: modified files save on change and on leave/focus changes
- Telescope: repo-scoped pickers by default, toggle with `<leader>fT`, display `filename — relative/path`

## Removing Configs

```bash
stow -D <package>
```

## License

MIT
