#!/usr/bin/env bash

# Fish shell installation script
# -----------------------------

# Source utility functions
source "$(dirname "$0")/../utils/colors.sh"
source "$(dirname "$0")/../utils/os_detection.sh"

install_fish() {
    info_msg "Setting up fish shell..."
    
    # Check if fish is installed
    if ! command -v fish >/dev/null 2>&1; then
        info_msg "Installing fish shell..."
        if is_macos; then
            brew install fish
        elif is_ubuntu; then
            sudo apt-add-repository -y ppa:fish-shell/release-3
            sudo apt update
            sudo apt install -y fish
        else
            error_msg "Unsupported OS for automatic fish installation"
            return 1
        fi
    else
        info_msg "Fish shell is already installed"
    fi
    
    # Set fish as default shell if it isn't already
    if [[ "$SHELL" != *"fish"* ]]; then
        info_msg "Setting fish as default shell..."
        chsh -s "$(which fish)"
        success_msg "Fish set as default shell (will take effect after logout)"
    fi
    
    # Install fisher (plugin manager)
    if ! fish -c "type fisher" >/dev/null 2>&1; then
        info_msg "Installing fisher plugin manager..."
        fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
        success_msg "Fisher installed"
    fi
    
    # Install useful plugins
    info_msg "Installing fish plugins..."
    fish -c "fisher install jorgebucaran/autopair.fish"
    fish -c "fisher install PatrickF1/fzf.fish"
    fish -c "fisher install jethrokuan/z"
    
    success_msg "Fish shell setup completed"
    return 0
}

# Run the installation function
install_fish

