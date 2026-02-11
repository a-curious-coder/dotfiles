#!/bin/bash

# --- Setup & Principles ---
# Clear, concise, and idempotent.
# Only acts when necessary.
set -e

# Colors for clarity
BOLD='\033[1m'
NC='\033[0m' 

install_msg() { echo -e "${BOLD}Setup:${NC} $1..."; }
skip_msg() { echo -e "${BOLD}Skipped:${NC} $1 is already present."; }

# 1. Update system baseline
sudo apt update -qq

# 2. Standard APT Packages (btop, tldr)
for pkg in btop tldr; do
    if ! command -v $pkg &> /dev/null; then
        install_msg "Installing $pkg"
        sudo apt install -y $pkg
    else
        skip_msg "$pkg"
    fi
done

# 2b. Noto Serif font (for Calibre reader consistency)
if command -v fc-list &> /dev/null && fc-list | grep -qi "Noto Serif"; then
    skip_msg "Noto Serif font"
else
    install_msg "Installing Noto Serif font (fonts-noto-core)"
    sudo apt install -y fonts-noto-core
fi

# 3. Zoxide (Smarter cd)
if ! command -v zoxide &> /dev/null; then
    install_msg "zoxide"
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    skip_msg "zoxide"
fi

# 4. Eza (Modern ls)
if ! command -v eza &> /dev/null; then
    install_msg "eza"
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
else
    skip_msg "eza"
fi

# 5. Lazygit
if ! command -v lazygit &> /dev/null; then
    install_msg "lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
else
    skip_msg "lazygit"
fi

# 6. Lazydocker
if ! command -v lazydocker &> /dev/null; then
    install_msg "lazydocker"
    curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
else
    skip_msg "lazydocker"
fi

# 7. Ghostty (The "Modern" Terminal)
# Note: Ghostty is often distributed via community DEBs for Ubuntu 24.04+
if ! command -v ghostty &> /dev/null; then
    install_msg "ghostty (via community installer)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
else
    skip_msg "ghostty"
fi

echo -e "\n${BOLD}Workspace complete.${NC} Modern tools are ready."
