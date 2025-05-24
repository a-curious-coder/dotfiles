# 🚀 Dotfiles - Automated Development Environment

One command to set up your entire Linux development environment!

## 🎯 What This Does

This repository automates the installation and configuration of a complete development environment including:

- **🐚 Modern Shell**: Zsh with Oh My Zsh and Powerlevel10k theme
- **🖥️ Terminal**: Ghostty terminal with custom shaders and configurations
- **🛠️ Development Tools**: Docker, LazyDocker, LazyGit, Git, VS Code, Neovim
- **🔧 Programming Languages**: Go, Rust, Node.js with version managers
- **⚡ Modern CLI Tools**: lsd, bat, ripgrep, fd, fzf, and more
- **📝 Configuration Files**: Optimized configs for all tools

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles

# Navigate to the directory
cd ~/.dotfiles

# Make the installer executable and run it
chmod +x install.sh
./install.sh
```

That's it! ☕ Grab a coffee while your development environment sets itself up.

## 📋 What Gets Installed

### 🔧 Core Tools
- **Docker Engine** - Container platform
- **LazyDocker** - Docker management TUI
- **LazyGit** - Git management TUI
- **Ghostty** - Modern terminal emulator
- **VS Code** - Code editor with essential extensions
- **Neovim** - Modern text editor
- **Git** - Version control with optimized configuration

### 🐚 Shell Environment
- **Zsh** - Modern shell
- **Oh My Zsh** - Zsh framework
- **Powerlevel10k** - Beautiful and fast theme
- **Auto-suggestions** - Command completion
- **Syntax highlighting** - Code highlighting in terminal

### 🌐 Programming Languages
- **Go** - Systems programming language
- **Rust** - Memory-safe systems language
- **Node.js** - JavaScript runtime
- **NVM** - Node version manager

### ⚡ Modern CLI Tools
- **lsd** - Modern ls with colors and icons
- **bat** - Modern cat with syntax highlighting
- **ripgrep** - Fast grep alternative
- **fd** - Fast find alternative
- **fzf** - Fuzzy finder

## 🎨 Customization

### Adding Software Packages

Edit `config.yaml` to add new packages:

```yaml
packages:
  your-package:
    name: "Package Name"
    install_method: "apt"  # or "snap", "script", "binary", "appimage"
    package: "package-name"
    verify_command: "package-name --version"
```

### Modifying Configurations

- **Zsh**: Edit `zsh/.zshrc`, `zsh/.zsh_aliases`, `zsh/.zsh_functions`
- **Git**: Edit `git/.gitconfig`
- **Ghostty**: Edit `ghostty/.config/ghostty/config`
- **Tmux**: Edit `tmux/.tmux.conf`

## 📁 Repository Structure

```
.dotfiles/
├── install.sh              # Main installation script
├── config.yaml             # Software package definitions
├── scripts/                 # Installation scripts
│   ├── install-packages.sh  # Package installation logic
│   ├── setup-dotfiles.sh    # Stow configuration setup
│   └── post-install.sh      # Post-installation tasks
├── zsh/                     # Zsh configuration
├── git/                     # Git configuration
├── ghostty/                 # Ghostty terminal configuration
├── tmux/                    # Tmux configuration
├── nvim/                    # Neovim configuration
└── .stowrc                  # Stow configuration
```

## 🔧 Manual Steps (Optional)

After installation, you may want to:

1. **Configure Git user info**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. **Customize Powerlevel10k theme**:
   ```bash
   p10k configure
   ```

3. **Install additional VS Code extensions**:
   ```bash
   code --install-extension extension-name
   ```

## 🆘 Troubleshooting

### Script Fails
- Ensure you have `sudo` access
- Check internet connection
- Run `sudo apt update` first

### Missing Software
- Check `config.yaml` for package definitions
- Verify package names for your Ubuntu/Debian version
- Some packages may require different repositories

### Permission Issues
- Run `sudo chown -R $(whoami):$(whoami) ~/.config`
- Logout and login for group changes (Docker) to take effect

## 🤝 Contributing

Feel free to:
- Add new software packages to `config.yaml`
- Improve configuration files
- Submit issues and feature requests
- Create pull requests

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**Happy coding!** 🎉✨

Made with ❤️ for developers who value automation and beautiful terminals.
