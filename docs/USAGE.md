# Usage Guide

## 🚀 Quick Start

```bash
# Fresh installation
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh

# Update existing installation
cd ~/.dotfiles && git pull && ./install.sh
```

## 🛠️ Essential Commands

### Shell Functions
```bash
extract file.tar.gz          # Extract any archive format
mkcd new-project             # Create directory and cd into it
gclone https://github.com/   # Clone repo and cd into it
backup important-file.txt    # Backup file with timestamp
killport 3000               # Kill process using port 3000
update-all                  # Update system, Oh My Zsh, packages
```

### CTF & Security
```bash
ctf-workspace challenge-name # Create organized CTF workspace
portscan target.com         # Quick port scan
webenum http://target.com   # Web directory enumeration
ctf-extract suspicious.bin  # Analyze files for CTF
```

### Git Aliases
```bash
git st          # status
git co branch   # checkout
git lg          # pretty log graph
git cleanup     # prune and clean
```

### Docker Shortcuts
```bash
d               # docker
dc              # docker-compose
dps             # docker ps
ld              # lazydocker (TUI)
lg              # lazygit (TUI)
```

## 🎨 Customization

### Add New Software
Edit `config.yaml`:
```yaml
packages:
  your-tool:
    name: "Your Tool"
    install_method: "apt"
    package: "tool-name"
    verify_command: "tool-name --version"
```

### Shell Customization
- **Aliases**: Edit `zsh/.zsh_aliases`
- **Functions**: Edit `zsh/.zsh_functions`
- **Environment**: Edit `zsh/.zshrc`

### Terminal Colors
Edit `ghostty/.config/ghostty/config`:
```toml
font-size = 16
font-family = "Your Font"
background = "#your-color"
```

## 🔧 Maintenance

```bash
# Update everything
update-all

# Backup dotfiles
cp -r ~/.dotfiles ~/dotfiles-backup-$(date +%Y%m%d)

# Restore after updates
cd ~/.dotfiles && git pull && stow */

# Test configuration
./test.sh
```

## 🐛 Troubleshooting

### Common Issues

**Zsh not default shell:**
```bash
chsh -s $(which zsh)
# Then logout/login
```

**Oh My Zsh not loading:**
```bash
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Stow conflicts:**
```bash
# Remove existing config first
rm ~/.existing-config
# Then re-stow
cd ~/.dotfiles && stow package-name
```

**Permission issues:**
```bash
chmod +x install.sh
sudo ./install.sh
```

---

For detailed security tools usage, see `CTF-GUIDE.md`.
