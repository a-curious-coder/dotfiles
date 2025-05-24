# Dotfiles Usage Guide

## 🚀 Quick Start

### Fresh Installation
```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Update Existing Installation
```bash
cd ~/.dotfiles
git pull
./install.sh
```

## 📋 What's Included

### 🔧 Development Tools
- **Docker** - Container platform
- **LazyDocker** - Docker TUI management
- **LazyGit** - Git TUI management
- **VS Code** - Code editor with extensions
- **Neovim** - Terminal-based editor
- **Ghostty** - Modern terminal emulator

### 🐚 Shell Environment
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** theme
- **Auto-suggestions** and syntax highlighting
- **Custom aliases** and functions

### 💻 Programming Languages
- **Go** - Latest version
- **Rust** - Via rustup
- **Node.js** - Via NVM

### ⚡ Modern CLI Tools
- **lsd** - Modern `ls`
- **bat** - Modern `cat`
- **ripgrep** - Fast grep
- **fd** - Fast find
- **fzf** - Fuzzy finder

## 🎨 Customization

### Adding New Software

Edit `config.yaml`:

```yaml
packages:
  your-tool:
    name: "Your Tool"
    install_method: "apt"  # or snap, script, binary, appimage
    package: "tool-name"
    verify_command: "tool-name --version"
    post_install:  # optional
      - "echo 'Tool installed'"
```

### Shell Customization

**Aliases**: Edit `zsh/.zsh_aliases`
```bash
alias myalias='command'
```

**Functions**: Edit `zsh/.zsh_functions`
```bash
myfunction() {
    echo "Hello from function"
}
```

**Environment**: Edit `zsh/.zshrc`

### Git Configuration

Edit `git/.gitconfig` or use commands:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Terminal Configuration

Edit `ghostty/.config/ghostty/config`:
```toml
font-size = 16
font-family = "Your Font"
background = "#your-color"
```

## 🛠️ Useful Commands

### Shell Functions (Available after installation)

```bash
# Extract any archive
extract file.tar.gz

# Create directory and cd into it
mkcd new-project

# Clone repo and cd into it
gclone https://github.com/user/repo

# Backup a file
backup important-file.txt

# Kill process by port
killport 3000

# Update everything
update-all

# Create new development project
newproject my-app
```

### Git Aliases (Available after installation)

```bash
# Status and basic operations
git st          # status
git co branch   # checkout
git br          # branch
git ci          # commit
git ca          # commit -a
git cm "msg"    # commit -m

# Advanced operations
git lg          # pretty log graph
git lol         # detailed log graph
git unstage     # unstage files
git last        # show last commit
git amend       # amend last commit

# Cleanup
git cleanup     # prune and clean
```

### Docker Shortcuts

```bash
# Docker aliases
d               # docker
dc              # docker-compose
dps             # docker ps
di              # docker images
dex container   # docker exec -it container

# Management
ld              # lazydocker
lg              # lazygit
```

## 🔧 Maintenance

### Update System
```bash
update-all  # Updates system, Oh My Zsh, Rust, npm packages
```

### Backup Configuration
```bash
# Backup current dotfiles
cp -r ~/.dotfiles ~/dotfiles-backup-$(date +%Y%m%d)
```

### Restore Configuration
```bash
cd ~/.dotfiles
git stash  # Save local changes
git pull   # Get updates
git stash pop  # Restore local changes
```

### Add New Stow Package
```bash
cd ~/.dotfiles
mkdir new-tool
# Add config files to new-tool/
stow new-tool
```

### Remove Stow Package
```bash
cd ~/.dotfiles
stow -D package-name  # Remove symlinks
rm -rf package-name   # Remove directory
```

## 🐛 Troubleshooting

### Installation Issues

**Permission denied**:
```bash
chmod +x install.sh
sudo ./install.sh
```

**Missing dependencies**:
```bash
sudo apt update
sudo apt install curl wget git
```

**Stow conflicts**:
```bash
# Remove existing config
rm ~/.existing-config
# Then re-run
cd ~/.dotfiles && stow package-name
```

### Shell Issues

**Zsh not default**:
```bash
chsh -s $(which zsh)
# Then logout/login
```

**Oh My Zsh not loading**:
```bash
# Reinstall Oh My Zsh
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Powerlevel10k issues**:
```bash
# Reconfigure theme
p10k configure
```

### VS Code Issues

**Extensions not installing**:
```bash
# Install manually
code --install-extension ms-vscode.vscode-json
```

**Settings not loading**:
```bash
# Check symlink
ls -la ~/.config/Code/User/settings.json
# Should point to ~/.dotfiles/vscode/.config/Code/User/settings.json
```

## 📚 Additional Resources

### Learning Resources
- [Oh My Zsh Documentation](https://github.com/ohmyzsh/ohmyzsh)
- [Powerlevel10k Configuration](https://github.com/romkatv/powerlevel10k)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Ghostty Documentation](https://ghostty.org)

### Useful Links
- [Nerd Fonts](https://www.nerdfonts.com/) - For terminal icons
- [Catppuccin](https://catppuccin.com/) - Color schemes
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix) - CLI alternatives

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./test.sh`
5. Submit a pull request

---

**Happy coding!** 🎉
