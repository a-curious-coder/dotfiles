# Dotfiles

Personal configurations managed with GNU Stow. Plain text, portable, version-controlled.

## Philosophy

These configs follow [Kepano's principles](kepano-philosophy.md):

- **File over app** - Plain text configs that outlive the tools
- **Radical minimalism** - Only what serves a purpose
- **Reduced friction** - Consistent keybinds, one font stack, one color palette
- **Intentional constraints** - Start vanilla, add only when friction is unbearable

## Structure

Each directory is a stow package. Run `stow <package>` to symlink.

```
dotfiles/
├── aerospace/      macOS tiling window manager
├── ags/            Aylur's GTK Shell (Hyprland widgets)
├── btop/           Resource monitor
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
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Symlink what you need
stow git zsh starship tmux nvim ghostty

# Or use the setup script
./setup --mode dotfiles
```

See [SETUP.md](SETUP.md) for package installation options.

## Platform Notes

**Linux (Hyprland)**
```bash
stow hypr waybar rofi ags swaync wlogout
```

**macOS**
```bash
stow aerospace
```

**Common (both platforms)**
```bash
stow git zsh starship tmux nvim ghostty btop lazygit lazydocker fastfetch ripgrep vscode
```

## Scripts

| File | Purpose |
|------|---------|
| `packages.yaml` | Unified package definitions for setup script |
| `install-modern-tools.sh` | Install CLI tools (glow, zellij, dust, navi, posting, etc.) |
| `ubuntu_install.sh` | Ubuntu-specific package installation |

## Neovim

The nvim config has its own documentation:

- `nvim/.config/nvim/README.md` - Full documentation
- Requires: Neovim >= 0.10, Node.js, ripgrep, fd, Nerd Font

## Removing Configs

```bash
stow -D <package>
```

## License

MIT
