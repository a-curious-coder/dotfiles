# 🏠 Dotfiles

Modern, cross-platform dotfiles with GNU Stow and unified package management.

## ✨ Features

- **Cross-platform**: Works on Linux and macOS
- **GNU Stow**: Clean symlink management
- **Unified config**: Single source of truth for packages
- **Interactive**: Choose what to install
- **Modular**: Install by category or individual tools

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the installer
./setup

# Or with options
./setup --interactive                    # Choose packages interactively
./setup --mode dotfiles                 # Only setup dotfiles
./setup --categories cli,development    # Install specific categories
./setup --dry-run                       # Preview what would be done
```

## 📁 Structure

```
.dotfiles/
├── setup                           # Main installer script
├── sync-dotfiles                   # Multi-machine sync script
├── packages.yaml                   # Unified package configuration
├── ghostty/                        # Ghostty terminal config
├── git/                           # Git configuration (includes delta config)
├── lazygit/                       # Lazygit terminal UI for git
├── nvim/                          # Neovim configuration (see nvim/INSTALL.md)
├── starship/                      # Starship prompt (alternative to powerlevel10k)
├── tmux/                          # Tmux configuration
├── vscode/                        # VS Code settings
├── zsh/                           # Zsh and Oh My Zsh config
└── scripts/                       # Installation scripts
    ├── lib/                       # Shared libraries
    └── ...
```

## 📝 Special Configurations

### Neovim Setup

The Neovim configuration is comprehensive and requires additional dependencies:

**Quick Install:**
```bash
# Install Neovim and all dependencies
./setup --categories development,cli,terminal

# Stow the nvim configuration
stow nvim
```

**📖 For detailed Neovim installation instructions, see [nvim/INSTALL.md](nvim/INSTALL.md)**

**Neovim Prerequisites:**
- Neovim >= 0.10.0
- Node.js (for LSP servers)
- ripgrep, fd, fzf (for search functionality)
- A Nerd Font (for icons)

**Documentation:**
- Installation Guide: `nvim/INSTALL.md`
- Quick Reference: `nvim/QUICKREF.md`
- Full Documentation: `nvim/.config/nvim/README.md`
- Design Document: `nvim/DESIGN_PLAN.md`

## 🛠 Configuration

### Package Categories

- **development**: Core development tools (Docker, VS Code, Git)
- **cli**: Modern CLI tools (bat, ripgrep, fd, fzf, eza, zoxide, lazygit, delta, tldr, btop)
- **security**: Security and CTF tools (nmap, wireshark, etc.)
- **language**: Programming languages (Node.js, Go, Rust)
- **terminal**: Terminal applications (Ghostty, tmux, starship)

### Customization

Edit `packages.yaml` to:
- Add new packages
- Modify installation methods
- Set platform-specific configurations
- Define post-install commands

## 📝 Usage Examples

```bash
# Full installation
./setup --mode full

# Just dotfiles (no packages)
./setup --mode dotfiles

# Interactive package selection
./setup --interactive

# Install specific categories
./setup --categories development,cli

# Preview changes
./setup --dry-run
```

## 🔄 Syncing Across Machines

Use the `sync-dotfiles` script to keep your dotfiles synchronized across multiple machines:

```bash
# Push local changes to remote
./sync-dotfiles push

# Pull changes from remote
./sync-dotfiles pull

# Check sync status
./sync-dotfiles status

# View differences
./sync-dotfiles diff

# List all machines
./sync-dotfiles list-machines
```

**See [SYNC-GUIDE.md](SYNC-GUIDE.md) for detailed sync instructions.**

## 🔧 Manual Operations

```bash
# Setup dotfiles only
stow ghostty git nvim tmux vscode zsh

# Remove dotfiles
stow -D ghostty git nvim tmux vscode zsh

# Update packages
./setup --mode packages --force
```

## 🐛 Troubleshooting

- Run `./setup --dry-run` to see what would be installed
- Check logs in the terminal for specific error messages
- Ensure you have `curl`, `git`, and platform package manager installed

## 📄 License

MIT License - see LICENSE file for details.
