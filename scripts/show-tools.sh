#!/usr/bin/env bash

# Show Available Tools Script
# ===========================

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════╗
║              INSTALLED TOOLS SUMMARY             ║
╚══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to check if command exists and show version
check_tool() {
    local tool="$1"
    local cmd="${2:-$1}"
    local version_flag="${3:---version}"

    # Check for snap packages first
    if [[ "$cmd" == "postman" || "$cmd" == "insomnia" || "$cmd" == "dbeaver-ce" ]]; then
        if snap list "$cmd" &> /dev/null; then
            local version=$(snap list "$cmd" 2>/dev/null | tail -n +2 | awk '{print $2}' | head -1)
            echo -e "${GREEN}✓${NC} $tool - $version"
        else
            echo -e "${YELLOW}✗${NC} $tool - not found"
        fi
    elif command -v "$cmd" &> /dev/null; then
        # Use timeout to prevent hanging commands and clean up output
        local version=$(timeout 5s bash -c "$cmd $version_flag 2>/dev/null" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' | cut -c1-80)

        # If version is empty or just whitespace, show as installed
        if [[ -z "$version" || "$version" =~ ^[[:space:]]*$ ]]; then
            version="installed"
        fi

        echo -e "${GREEN}✓${NC} $tool - ${version}"
    else
        echo -e "${YELLOW}✗${NC} $tool - not found"
    fi
}

echo -e "${BLUE}🔧 Development Tools:${NC}"
check_tool "Docker" "docker"
check_tool "Docker Compose" "docker-compose"
check_tool "LazyDocker" "lazydocker"
check_tool "LazyGit" "lazygit"
check_tool "Git" "git"
check_tool "VS Code" "code"
check_tool "Neovim" "nvim"
echo ""

echo -e "${BLUE}🌐 Programming Languages:${NC}"
check_tool "Node.js" "node"
# Special handling for Go which might need GOROOT set
if command -v go &> /dev/null; then
    go_version=$(timeout 5s bash -c "GOROOT=/usr/lib/go-1.23 go version 2>/dev/null || go version 2>/dev/null" | head -1 | sed 's/^[[:space:]]*//' | cut -c1-80)
    if [[ -n "$go_version" && ! "$go_version" =~ ^[[:space:]]*$ ]]; then
        echo -e "${GREEN}✓${NC} Go - ${go_version}"
    else
        echo -e "${GREEN}✓${NC} Go - installed"
    fi
else
    echo -e "${YELLOW}✗${NC} Go - not found"
fi
check_tool "Rust" "rustc"
check_tool "Python 3" "python3"
check_tool "rbenv" "rbenv"
echo ""

echo -e "${BLUE}🔒 Security Tools:${NC}"
check_tool "Nmap" "nmap"
check_tool "Masscan" "masscan"
check_tool "Wireshark" "wireshark"
check_tool "Burp Suite" "burpsuite"
check_tool "Gobuster" "gobuster" "version"
check_tool "DIRB" "dirb"
check_tool "Ghidra" "ghidra"
check_tool "Radare2" "r2" "-version"
check_tool "GDB" "gdb"
check_tool "Hashcat" "hashcat"
check_tool "John the Ripper" "john"
check_tool "Binwalk" "binwalk"
check_tool "Steghide" "steghide"
echo ""

echo -e "${BLUE}🌐 Full-Stack Tools:${NC}"
check_tool "Postman" "postman" "--help"
check_tool "Insomnia" "insomnia" "--help"
check_tool "DBeaver" "dbeaver-ce" "--help"
check_tool "MySQL Client" "mysql" "--help"
check_tool "PostgreSQL Client" "psql" "--help"
check_tool "Redis CLI" "redis-cli" "--help"
check_tool "AWS CLI" "aws" "--version"
check_tool "Terraform" "terraform" "--version"
check_tool "Kubectl" "kubectl" "version --client --short"
echo ""

echo -e "${BLUE}⚡ Modern CLI Tools:${NC}"
check_tool "lsd (modern ls)" "lsd"
check_tool "bat (modern cat)" "batcat"
check_tool "ripgrep (rg)" "rg"
check_tool "fd (modern find)" "fdfind"
check_tool "fzf (fuzzy finder)" "fzf"
check_tool "htop" "htop"
check_tool "jq" "jq"
check_tool "yq" "yq"
echo ""

echo -e "${BLUE}🐚 Shell Environment:${NC}"
check_tool "Zsh" "zsh"
# Special check for Oh My Zsh
if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    omz_version="installed"
    if command -v omz &> /dev/null; then
        omz_version=$(omz version 2>/dev/null || echo "installed")
    fi
    echo -e "${GREEN}✓${NC} Oh My Zsh - ${omz_version}"
else
    echo -e "${YELLOW}✗${NC} Oh My Zsh - not found"
fi
check_tool "Tmux" "tmux" "-V"
echo ""

echo -e "${CYAN}🎉 Installation Summary:${NC}"
echo "• $(grep -c '^  [a-z]' ~/.dotfiles/config.yaml 2>/dev/null || echo "60+") software packages configured"
echo "• CTF and security tools ready"
echo "• Full-stack development environment"
echo "• Modern CLI tools with aliases"
echo ""

echo -e "${YELLOW}📖 Quick Start:${NC}"
echo "• Type 'ctf-workspace challenge-name' to start a CTF"
echo "• Use 'portscan target.com' for quick reconnaissance"
echo "• Run 'webenum http://target.com' for web enumeration"
echo "• Check 'CTF-GUIDE.md' for detailed usage examples"
echo ""

echo -e "${CYAN}Happy hacking! 🎭${NC}"
