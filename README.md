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
├── setup                    # Main installer script
├── packages.yaml           # Unified package configuration
├── ghostty/                # Ghostty terminal config
├── git/                    # Git configuration
├── nvim/                   # Neovim configuration  
├── tmux/                   # Tmux configuration
├── vscode/                 # VS Code settings
├── zsh/                    # Zsh and Oh My Zsh config
└── scripts/                # Installation scripts
    ├── lib/                # Shared libraries
    └── ...
```

## 🛠 Configuration

### Package Categories

- **development**: Core development tools (Docker, VS Code, Git)
- **cli**: Modern CLI tools (bat, ripgrep, fd, fzf)
- **security**: Security and CTF tools (nmap, wireshark, etc.)
- **language**: Programming languages (Node.js, Go, Rust)
- **terminal**: Terminal applications (Ghostty, tmux)

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
