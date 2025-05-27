# 🚀 Modern Development Dotfiles

**Transform your Linux environment into a powerful development and security research workstation.**

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

This dotfiles setup provides **53 carefully curated tools** for development, security research, and daily productivity. Each tool is chosen for its practical value and includes sensible defaults.

## 📦 What's Included

### Core Development
- **Docker & LazyDocker** - Container platform with visual management TUI
- **LazyGit** - Beautiful Git interface that makes version control intuitive
- **VS Code & Neovim** - Both GUI and terminal editors with full LSP support
- **Ghostty** - GPU-accelerated terminal emulator for smooth performance

### Programming Languages
- **Go, Rust, Node.js, Python** - Complete development environments with package managers
- **Language servers** - Auto-completion and error checking for all major languages

### Modern CLI Replacements
- **ripgrep** → faster grep • **bat** → better cat • **lsd** → prettier ls
- **fd** → simpler find • **fzf** → fuzzy finder • **htop** → better top

### Database & API Tools
- **Postman** - API testing platform with beautiful interface
- **Insomnia** - Lightweight REST client for API development
- **DBeaver** - Universal database tool for SQL databases
- **MySQL/PostgreSQL** - Database clients for development work

### Cloud & Infrastructure
- **AWS CLI** - Amazon Web Services command-line interface
- **Terraform** - Infrastructure as code for cloud deployments
- **Kubectl** - Kubernetes cluster management and deployment

## 🔐 Security & CTF Tools

### Network Analysis
- **Nmap** - Network discovery and port scanning
- **Masscan** - Ultra-fast port scanner for large networks
- **Wireshark** - Deep packet analysis and protocol understanding

### Web Security
- **Burp Suite** - Industry-standard web application security testing
- **Gobuster** - Fast directory and subdomain brute-forcing
- **DIRB** - Web content scanner for finding hidden resources

### Reverse Engineering
- **Ghidra** - NSA's powerful reverse engineering suite (free IDA Pro alternative)
- **Radare2** - Command-line reverse engineering framework
- **GDB** - GNU debugger with Python scripting support

### Cryptography & Passwords
- **Hashcat** - GPU-accelerated password cracking
- **John the Ripper** - Classic password cracking with extensive format support

### Forensics
- **Binwalk** - Firmware analysis and file extraction
- **Steghide** - Hide and extract data in images/audio

## 🐍 Programming Languages

- **Go** - Fast compilation, excellent concurrency, perfect for system tools
- **Rust** - Memory-safe systems programming with zero-cost abstractions
- **Node.js** - JavaScript runtime for full-stack web development
- **Python 3** - Data science, automation, and security tool development

## 🐚 Enhanced Shell Experience

- **Oh My Zsh** - Plugin framework with 200+ plugins and themes
- **Powerlevel10k** - Fast, customizable prompt with Git status indicators
- **Auto-suggestions** - Command completion based on history
- **Syntax highlighting** - Visual feedback for commands as you type
- **CTF functions** - Specialized aliases like `portscan`, `webenum`, `ctf-workspace`

## Installation Modes

1. **Interactive Tool Selection** - Use `./scripts/manage-tools.sh` to pick specific tools
2. **Category-based** - Enable/disable entire categories (security, development, etc.)
3. **Full Install** - Everything for complete development environment
4. **Dotfiles Only** - Just shell and editor configurations

### 🎯 Smart Tool Selection

```bash
# Launch the interactive tool manager
./scripts/manage-tools.sh

# Configure what gets installed before running setup
# Enable/disable tools by category or individually
# See installation estimates and tool descriptions
```

## Quick Start

```bash
# 1. Configure your tool preferences
./scripts/manage-tools.sh

# 2. Configure Git credentials securely
./scripts/setup-git-user.sh

# 3. See what's installed
show-tools

# 4. Start a CTF workspace
ctf-workspace hackthebox-machine
```

## 🔐 Secure Git Configuration

This dotfiles setup uses a secure approach to handle your personal git credentials:

- **Public config** (`git/.gitconfig`) - Contains aliases, colors, and preferences (tracked in repo)
- **Private config** (`~/.gitconfig.local`) - Contains your name/email (gitignored, local only)

### Setup Your Credentials

```bash
# Run the interactive setup script
./scripts/setup-git-user.sh

# This creates ~/.gitconfig.local with your personal details
# The file is automatically added to .gitignore
```

### Benefits

- ✅ **Privacy** - Your email/name never gets committed to the public repo
- ✅ **Sharing** - Others can clone your dotfiles without credential conflicts  
- ✅ **Security** - No accidental exposure of personal information
- ✅ **Flexibility** - Different credentials per machine if needed

### Manual Configuration (Alternative)

```bash
# Create the local config file manually
cat > ~/.gitconfig.local << EOF
[user]
    name = Your Name
    email = your.email@example.com
EOF
```

## Why These Tools?

- **Faster feedback loops** - Modern CLI tools are 10-100x faster
- **Better visualization** - GUIs for complex tasks like Docker and Git
- **Professional capabilities** - Industry-standard security and development tools
- **Consistent environments** - Dotfiles ensure your setup works everywhere

---

**Get started in 2 minutes.** 🚀
