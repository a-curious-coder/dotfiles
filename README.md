# Dotfiles

Personal configurations managed with GNU Stow. Plain text, portable, version-controlled.

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
├── fastfetch/      System info (replaces neofetch)
├── ghostty/        Terminal emulator
├── git/            Git config with delta for diffs
├── hypr/           Hyprland compositor
├── lazydocker/     Docker TUI
├── lazygit/        Git TUI
├── nvim/           Neovim
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
stow hypr waybar rofi ags swaync wlogout calibre-linux
```

**macOS**
```bash
stow aerospace sketchybar calibre-macos
```

**Common (both platforms)**
```bash
stow git zsh starship tmux nvim ghostty btop lazygit lazydocker fastfetch ripgrep vscode
```

**Calibre (auto-select package by OS)**
```bash
./stow-calibre.sh

# Re-apply reader style after Calibre runtime rewrites
./apply-calibre-reader-style.sh

# Validate symlinks + key settings
./calibre-check.sh
```

## Scripts

| File | Purpose |
|------|---------|
| `packages.yaml` | Unified package definitions for setup script |
| `stow-calibre.sh` | Stow the correct Calibre package for current OS |
| `apply-calibre-reader-style.sh` | Idempotently patch Calibre reader settings |
| `calibre-check.sh` | Validate Calibre symlinks and expected settings |
| `install-modern-tools.sh` | Install CLI tools (glow, zellij, dust, navi, posting, etc.) |
| `setup-tmux.sh` | Stow tmux config, install/update TPM, and install plugins |
| `ubuntu_install.sh` | Ubuntu-specific package installation |

Docs:
- `docs/calibre.md` (Calibre profile and validation)
- `docs/CTF-GUIDE.md` (security/CTF command reference)

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
