# 🚀 Cross-Platform Modern Development Dotfiles

**Transform your Linux or macOS environment into a powerful development and security research workstation.**

## 🖥️ Platform Support

| Platform | Status | Package Manager | Features |
|----------|--------|-----------------|----------|
| **Linux** (Ubuntu/Debian) | ✅ Full Support | APT, Snap, Binary | All tools available |
| **macOS** | ✅ Full Support | Homebrew, Cask | Native app integration |
| **Windows** | 🔄 Planned | WSL2, Scoop | Future support |

## Quick Start

### Linux (Ubuntu/Debian)
```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh
```

### macOS  
```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install-cross-platform.sh
```

### Universal (Both Platforms)
```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install-cross-platform.sh
```

## 📦 What's Included

This dotfiles setup provides **53+ carefully curated tools** for development, security research, and daily productivity. Each tool is available on both Linux and macOS with platform-appropriate installation methods.

### Core Development
- **Docker & LazyDocker** - Container platform with visual management TUI
  - Linux: Docker Engine + LazyDocker binary
  - macOS: Docker Desktop + Homebrew LazyDocker
- **LazyGit** - Beautiful Git interface that makes version control intuitive
- **VS Code & Neovim** - Both GUI and terminal editors with full LSP support
- **Ghostty** - GPU-accelerated terminal emulator for smooth performance

### Programming Languages
- **Go, Rust, Node.js, Python** - Complete development environments
  - Linux: Package managers + binary installs
  - macOS: Homebrew formulas with native optimization
- **Language servers** - Auto-completion and error checking for all major languages

### Modern CLI Replacements
- **ripgrep** → faster grep • **bat** → better cat • **lsd** → prettier ls
- **fd** → simpler find • **fzf** → fuzzy finder • **htop** → better top
- *Available on both platforms via native package managers*

### Database & API Tools
- **Postman** - API testing platform 
  - Linux: Snap package
  - macOS: Native app via Homebrew Cask
- **Insomnia** - Lightweight REST client
- **DBeaver** - Universal database tool
- **MySQL/PostgreSQL** - Database clients

### Cloud & Infrastructure
- **AWS CLI** - Amazon Web Services command-line interface
- **Terraform** - Infrastructure as code for cloud deployments
- **Kubectl** - Kubernetes cluster management and deployment

## 🔐 Security & CTF Tools

### Network Analysis
- **Nmap** - Network discovery and port scanning
- **Masscan** - Ultra-fast port scanner for large networks
- **Wireshark** - Deep packet analysis and protocol understanding
  - Linux: APT package with user group setup
  - macOS: Native app with proper permissions

### Web Security
- **Burp Suite** - Industry-standard web application security testing
  - Linux: Custom installer with desktop integration
  - macOS: Homebrew Cask with native app support
- **Gobuster** - Fast directory and subdomain brute-forcing
- **DIRB** - Web content scanner for finding hidden resources

### Reverse Engineering
- **Ghidra** - NSA's powerful reverse engineering suite
  - Linux: Binary installation to /opt
  - macOS: Homebrew Cask with app bundle
- **Radare2** - Command-line reverse engineering framework
- **GDB** - GNU debugger with Python scripting support

### Cryptography & Passwords
- **Hashcat** - GPU-accelerated password cracking
- **John the Ripper** - Classic password cracking with extensive format support

### Forensics
- **Binwalk** - Firmware analysis and file extraction
- **Steghide** - Hide and extract data in images/audio

## 🐍 Programming Languages

Complete development environments for:
- **Python 3.11+** with pip3 and essential security libraries
- **Node.js LTS** with npm and development tools  
- **Go** latest stable with module support
- **Rust** with Cargo package manager
- **Ruby** with rbenv version manager

## 🐚 Enhanced Shell Experience

### Cross-Platform Zsh Setup
- **Oh My Zsh** - Framework with plugins and themes
- **Powerlevel10k** - Beautiful, fast prompt with Git integration
- **Auto-suggestions** - Fish-like autocompletion
- **Syntax highlighting** - Real-time command validation

### Smart Aliases & Functions
```bash
extract file.tar.gz          # Extract any archive format
mkcd new-project             # Create directory and cd into it  
gclone https://github.com/   # Clone repo and cd into it
backup important-file.txt    # Backup file with timestamp
killport 3000               # Kill process using port 3000
update-all                  # Update system, Oh My Zsh, packages
```

## Installation Modes

### 1. Full Installation (Recommended)
```bash
./install-cross-platform.sh
```
Installs everything: dotfiles, packages, shell setup, and development tools.

### 2. Dotfiles Only
```bash
./install-cross-platform.sh --dotfiles
```
Just shell and editor configurations without heavy packages.

### 3. Packages Only  
```bash
./install-cross-platform.sh --packages
```
Install tools without touching existing dotfiles.

### 4. Interactive Tool Selection
```bash
./scripts/manage-tools.sh
```
Pick specific tools and categories before installation.

## Platform-Specific Features

### Linux (Ubuntu/Debian)
- **APT integration** - Native package management
- **Snap support** - Modern app packaging
- **AppImage support** - Portable applications
- **System service management** - Docker, SSH, etc.

### macOS
- **Homebrew integration** - Native package management
- **Cask support** - GUI application management
- **App Store integration** - Native app installations
- **Xcode tools** - Development toolchain integration
- **Apple Silicon support** - Optimized for M1/M2 Macs

## 🎯 Smart Tool Selection

Configure your installation before running:

```bash
# Launch the interactive tool manager
./scripts/manage-tools.sh

# Enable/disable tools by category or individually
# See installation estimates and tool descriptions
# Platform-specific recommendations
```

Categories available:
- **Cybersecurity** - Penetration testing and CTF tools
- **Development** - Programming languages and editors  
- **Databases** - SQL clients and database tools
- **Cloud** - AWS, Terraform, Kubernetes
- **Productivity** - Modern CLI tools and utilities

## Quick Start Examples

```bash
# 1. Configure your tool preferences (optional)
./scripts/manage-tools.sh

# 2. Configure Git credentials securely  
./scripts/setup-git-user.sh

# 3. See what's installed
show-tools

# 4. Start a CTF workspace
ctf-workspace hackthebox-machine

# 5. Launch development tools
lazygit        # Beautiful Git interface
lazydocker     # Docker container management  
code .         # VS Code in current directory
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

## Why These Tools?

- **Cross-platform consistency** - Same tools work on Linux and macOS
- **Faster feedback loops** - Modern CLI tools are 10-100x faster
- **Better visualization** - GUIs for complex tasks like Docker and Git
- **Professional capabilities** - Industry-standard security and development tools
- **Native integration** - Platform-optimized installation and integration

## Troubleshooting

### Linux
```bash
# If packages fail to install
sudo apt update && sudo apt upgrade
./install-cross-platform.sh --packages

# If dotfiles conflicts occur
./install-cross-platform.sh --dotfiles
```

### macOS
```bash
# If Homebrew installation fails
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# If Xcode tools are missing
xcode-select --install

# If cask permissions fail
brew install --cask --no-quarantine <package>
```

---

**Get started in 2 minutes on any platform.** 🚀

*Support for Windows via WSL2 coming soon!*
