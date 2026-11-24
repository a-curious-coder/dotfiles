# Dotfiles Setup

This repo is managed with GNU Stow. Keep setup simple: install tools, stow only the packages you use, then validate.

## Prerequisites

- `git`
- `stow`
- `zsh` (recommended shell)

Install platform packages however you prefer, then continue below.

## Quick Start

```bash
git clone git@github.com:a-curious-coder/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### One-command bootstrap

```bash
./bootstrap.sh
```

This runs:
- `install-modern-tools.sh`
- stow for common and platform packages

### Core packages

```bash
stow git zsh starship nvim ghostty claude direnv herdr yazi
```

`git/` is gitignored (it holds personal and work identities), so a fresh clone
has no `git` package. Copy your `.gitconfig*` files into `git/` first, or stow
skips it.

After stowing `claude`, run `herdr integration install claude`. It writes
`~/.claude/hooks/herdr-agent-state.sh`, which `settings.json` calls. herdr owns
that file, so it is not in this repo.

### Linux desktop (Hyprland stack)

```bash
stow hypr kanshi waybar rofi swaync wlogout
```

### macOS only

```bash
stow llama opencode
```

### Common optional tools

```bash
stow btop lazygit lazydocker fastfetch
```

## Install Modern CLI Tools

Single installer path (cross-platform):

```bash
./install-modern-tools.sh
```

## Shell + Theme Helpers

After `stow zsh starship ghostty`, open a new shell and use:

```bash
prompt-style          # list prompt styles
prompt-style context  # switch style

ghostty-theme         # list Ghostty themes
ghostty-theme nord    # switch theme
```

## Validate

```bash
# Confirm symlinks exist
stow -nvt "$HOME" git zsh starship nvim ghostty claude direnv herdr yazi

# Neovim health
nvim +checkhealth +qa
```

## Remove a package

```bash
stow -D <package>
```
