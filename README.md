# 🚀 Dotfiles - Full-Stack Developer + CTF Edition

One command to set up your entire Linux development environment optimized for **full-stack development** and **Capture The Flag (CTF)** competitions!

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                      🛡️  DEVELOPER + SECURITY TOOLKIT  🛡️                     ║
║                                                                               ║
║  🔧 61+ Tools Automated    🐚 Modern Shell    🔒 CTF Ready    🌐 Full-Stack   ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

## What You Get

- **Modern Shell**: Zsh + Oh My Zsh + Powerlevel10k
- **Security Tools**: Nmap, Burp Suite, Ghidra, Hashcat, Wireshark
- **Development**: Docker, VS Code, Git, database clients, API tools
- **Languages**: Go, Rust, Node.js with version managers
- **CLI Tools**: bat, ripgrep, fzf, and modern alternatives

## Installation

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh && ./install.sh
```

> 📋 See full package list: [`show-tools`](./scripts/show-tools.sh) command after installation
> 🛡️ CTF workflows: See [CTF-GUIDE.md](./CTF-GUIDE.md)

## Key Features

### 🔒 Security & CTF (25+ tools)
- **Network**: Nmap, Masscan, Wireshark
- **Web**: Burp Suite, Gobuster, DIRB
- **Reverse**: Ghidra, Radare2, GDB
- **Crypto**: Hashcat, John the Ripper
- **Python**: Pwntools, Scapy, Impacket

### 🌐 Full-Stack Development
- **Containers**: Docker + LazyDocker
- **APIs**: Postman, Insomnia
- **Databases**: MySQL, PostgreSQL, DBeaver
- **Cloud**: AWS CLI, Terraform, kubectl
- **Version Control**: Git + LazyGit

### 🐚 Enhanced Shell
- CTF-specific aliases: `portscan`, `webenum`, `revshell`
- Security functions: `ctf-workspace`, `hashid`, `b64`
- Modern tools: `bat`, `ripgrep`, `fzf`

## Customization

**Add packages**: Edit `config.yaml`
```yaml
packages:
  your-tool:
    name: "Your Tool"
    install_method: "apt"
    package: "tool-name"
```

**Modify configs**:
- Shell: `zsh/` directory
- Git: `git/.gitconfig`
- Terminal: `ghostty/.config/ghostty/config`

## Quick Setup

After installation:
```bash
# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Customize shell theme
p10k configure

# Show installed tools
show-tools
```

## Troubleshooting

**Installation fails**: Ensure `sudo` access and internet connection
**Missing packages**: Check `config.yaml` package names
**Permissions**: Run `sudo chown -R $(whoami):$(whoami) ~/.config`

---

**Happy hacking!** 🎉 Made with ❤️ for developers and security researchers.
