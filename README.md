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
├── aerospace/      macOS tiling window manager
├── sketchybar/     Status bar (macOS)
├── ags/            Aylur's GTK Shell (Hyprland widgets)
├── btop/           Resource monitor
├── calibre-linux/  Calibre config for Linux (~/.config/calibre)
├── calibre-macos/  Calibre config for macOS (~/Library/Preferences/calibre)
├── espanso/        Text expansion snippets and settings
├── fastfetch/      System info (replaces neofetch)
├── ghostty/        Terminal emulator
├── git/            Git config with delta for diffs
├── hammerspoon/    macOS automation (cmd+drag, window helpers)
├── hypr/           Hyprland compositor
├── lazydocker/     Docker TUI
├── lazygit/        Git TUI
├── nvim/           Neovim
├── pavucontrol/    PulseAudio volume control UI state
├── ripgrep/        ripgrep config
├── rofi/           Application launcher
├── starship/       Shell prompt
├── swaync/         Notification center (Hyprland)
├── tmux/           Terminal multiplexer
├── vscode/         VS Code settings
├── waybar/         Status bar (Wayland)
├── wlogout/        Logout menu (Hyprland)
└── zsh/            Shell config, aliases, functions
```

## Install

```bash
git clone git@github.com:a-curious-coder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# One-command bootstrap: tools + stow + tmux plugins
./bootstrap.sh

# Or run setup steps manually:
# Symlink what you need
stow git zsh starship tmux nvim ghostty espanso

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
stow hypr waybar rofi ags swaync wlogout calibre-linux
stow pavucontrol
```

**macOS**
```bash
stow aerospace sketchybar hammerspoon calibre-macos
```

Then open Hammerspoon once and grant Accessibility permissions (required for `cmd` + drag move/resize behavior).

**Common (both platforms)**
```bash
stow git zsh starship tmux nvim ghostty btop lazygit lazydocker fastfetch ripgrep vscode espanso
```

## Espanso (Text Expansion)

`espanso` snippets live at `espanso/.config/espanso/match/*.yml`.

- Add/edit your prompt snippets in `espanso/.config/espanso/match/prompts.yml`
- Trigger snippets using their abbreviation (for example `;p-summarize`)
- On macOS, run `./scripts/setup-espanso-macos.sh` once after `stow espanso` to link espanso's native config path to `~/.config/espanso`

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
| `install-modern-tools.sh` | Install CLI tools (glow, zellij, dust, navi, posting, etc.) |
| `setup-tmux.sh` | Stow tmux config, install/update TPM, and install plugins |
| `scripts/setup-espanso-macos.sh` | Link `~/Library/Application Support/espanso` to `~/.config/espanso` on macOS |
| `ubuntu_install.sh` | Compatibility wrapper that delegates to `install-modern-tools.sh` |
| `discord_install.sh` | Arch Linux workaround script for Discord updates (suitable for cron) |
| `scripts/check-shell.sh` | Run `shellcheck` for maintained repo shell scripts |
| `scripts/run-nvim-text-specs.sh` | Run lightweight Neovim text-spec checks |

Docs:
- `docs/calibre.md` (Calibre profile and validation)

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
