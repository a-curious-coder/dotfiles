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
- `setup-tmux.sh` (TPM install/update + plugin install)

### Core packages (both macOS and Linux)

```bash
stow git zsh starship tmux nvim ghostty
```

### Linux desktop (Hyprland stack)

```bash
stow hypr waybar rofi ags swaync wlogout calibre-linux
```

### macOS desktop

```bash
stow aerospace sketchybar calibre-macos
```

### Common optional tools

```bash
stow btop lazygit lazydocker fastfetch ripgrep vscode
```

## Calibre Setup

Use the single helper script to keep platform differences and runtime rewrites manageable:

```bash
./calibre.sh

# Optional explicit subcommands
./calibre.sh stow
./calibre.sh apply
./calibre.sh check
./calibre.sh where
```

Details: `docs/calibre.md`.

## Install Modern CLI Tools

Single installer path (cross-platform):

```bash
./install-modern-tools.sh
```

Legacy Ubuntu entrypoint (kept for compatibility; delegates to the same installer):

```bash
./ubuntu_install.sh
```

## tmux + TPM Setup

One-command bootstrap:

```bash
./setup-tmux.sh
```

This script:
- stows the `tmux` package
- installs or updates TPM at `~/.tmux/plugins/tpm`
- installs declared tmux plugins
- reloads `~/.tmux.conf`

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
stow -nvt "$HOME" git zsh starship tmux nvim ghostty

# Neovim health
nvim +checkhealth +qa
```

## Remove a package

```bash
stow -D <package>
```
