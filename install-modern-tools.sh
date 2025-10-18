#!/usr/bin/env bash
# Quick installer for new modern CLI tools
# Run: ./install-modern-tools.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Modern CLI Tools Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install with brew (macOS)
install_brew() {
    local package=$1
    local name=$2
    
    if command_exists "$name"; then
        echo -e "${GREEN}✓${NC} $name already installed"
    else
        echo -e "${YELLOW}→${NC} Installing $name..."
        brew install "$package"
        echo -e "${GREEN}✓${NC} $name installed"
    fi
}

# Function to install with apt (Linux)
install_apt() {
    local package=$1
    local name=$2
    
    if command_exists "$name"; then
        echo -e "${GREEN}✓${NC} $name already installed"
    else
        echo -e "${YELLOW}→${NC} Installing $name..."
        sudo apt update -qq
        sudo apt install -y "$package"
        echo -e "${GREEN}✓${NC} $name installed"
    fi
}

echo -e "${BLUE}Installing tools for $OS...${NC}"
echo ""

if [[ "$OS" == "macos" ]]; then
    # Check if Homebrew is installed
    if ! command_exists brew; then
        echo -e "${RED}Homebrew not found. Installing...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    install_brew "zoxide" "zoxide"
    install_brew "eza" "eza"
    install_brew "lazygit" "lazygit"
    install_brew "git-delta" "delta"
    install_brew "tldr" "tldr"
    install_brew "btop" "btop"
    install_brew "starship" "starship"
    
elif [[ "$OS" == "linux" ]]; then
    # zoxide (install script)
    if ! command_exists zoxide; then
        echo -e "${YELLOW}→${NC} Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        echo -e "${GREEN}✓${NC} zoxide installed"
    else
        echo -e "${GREEN}✓${NC} zoxide already installed"
    fi
    
    install_apt "eza" "eza"
    
    # lazygit (from PPA)
    if ! command_exists lazygit; then
        echo -e "${YELLOW}→${NC} Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
        echo -e "${GREEN}✓${NC} lazygit installed"
    else
        echo -e "${GREEN}✓${NC} lazygit already installed"
    fi
    
    # delta
    if ! command_exists delta; then
        echo -e "${YELLOW}→${NC} Installing delta..."
        DELTA_VERSION="0.17.0"
        curl -Lo delta.tar.gz "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
        tar xf delta.tar.gz
        sudo install "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta" /usr/local/bin/
        rm -rf delta.tar.gz "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu"
        echo -e "${GREEN}✓${NC} delta installed"
    else
        echo -e "${GREEN}✓${NC} delta already installed"
    fi
    
    install_apt "tldr" "tldr"
    install_apt "btop" "btop"
    
    # starship (install script)
    if ! command_exists starship; then
        echo -e "${YELLOW}→${NC} Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        echo -e "${GREEN}✓${NC} starship installed"
    else
        echo -e "${GREEN}✓${NC} starship already installed"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Stow configurations:"
echo "   cd ~/.dotfiles"
echo "   stow git lazygit starship zsh"
echo ""
echo "2. Reload your shell:"
echo "   source ~/.zshrc"
echo ""
echo "3. Update tldr cache:"
echo "   tldr --update"
echo ""
echo "4. (Optional) Enable starship prompt:"
echo "   Edit ~/.zshrc and uncomment starship init"
echo ""
echo -e "${BLUE}See docs/NEW-TOOLS.md for usage guide!${NC}"
