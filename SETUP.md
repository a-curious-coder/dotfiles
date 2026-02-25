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
stow git zsh starship tmux nvim ghostty espanso
```

### Linux desktop (Hyprland stack)

```bash
stow hypr waybar rofi ags swaync wlogout calibre-linux
```

### macOS desktop (yabai stack)

```bash
stow yabai skhd sketchybar calibre-macos
```

### Common optional tools

```bash
stow btop lazygit lazydocker fastfetch ripgrep vscode
```

## macOS: yabai + skhd Requirements

### 1) Install and start services

```bash
brew tap koekeishiya/formulae
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
brew install sketchybar

yabai --start-service
skhd --start-service
```

### 2) Grant permissions

- `System Settings -> Privacy & Security -> Accessibility`
- Enable both `yabai` and `skhd`
- Restart both services after granting access

### 3) Configure scripting-addition (closest-to-Hypr mode)

For full control and Hypr-like behavior, follow the official yabai SIP/scripting-addition steps:

- https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection
- https://github.com/asmvik/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition

After SIP/sudoers setup:

```bash
yabai --restart-service
skhd --reload
```

### 4) Test key behavior

- `cmd + drag` move/resize windows (`mouse_action1/2`)
- `cmd + h/j/k/l` focus movement
- `cmd + shift + h/j/k/l` window warp
- `cmd + [1-9]` focus spaces

Migration and rollback details: `docs/yabai-migration.md`

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

## Espanso Setup

After `stow espanso`, add your prompt snippets in:

```bash
~/.config/espanso/match/prompts.yml
```

On macOS, link espanso's native config path once:

```bash
./scripts/setup-espanso-macos.sh
```

Then start espanso:

```bash
espanso service register
espanso start
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
stow -nvt "$HOME" git zsh starship tmux nvim ghostty espanso

# Neovim health
nvim +checkhealth +qa
```

## Remove a package

```bash
stow -D <package>
```
