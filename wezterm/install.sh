#!/usr/bin/env bash

# Wezterm installation script
# --------------------------

# Source utility functions
source "$(dirname "$0")/../utils/colors.sh"
source "$(dirname "$0")/../utils/os_detection.sh"

install_wezterm() {
    info_msg "Setting up Wezterm..."
    
    # Check if Wezterm is installed
    if ! command -v wezterm >/dev/null 2>&1; then
        info_msg "Installing Wezterm..."
        if is_macos; then
            brew install --cask wezterm
        elif is_ubuntu; then
            # Add the GPG key
            curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
            
            # Add the repository
            echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" | sudo tee /etc/apt/sources.list.d/wezterm.list
            
            # Install
            sudo apt update
            sudo apt install -y wezterm
        else
            error_msg "Unsupported OS for automatic Wezterm installation"
            return 1
        fi
    else
        info_msg "Wezterm is already installed"
    fi
    
    # Configure Wezterm
    WEZTERM_CONFIG="$HOME/.config/wezterm"
    if [ ! -d "$WEZTERM_CONFIG" ]; then
        info_msg "Setting up Wezterm configuration..."
        mkdir -p "$WEZTERM_CONFIG"
        
        # Copy configuration files from dotfiles
        cp -r "$(dirname "$0")/.config/wezterm/"* "$WEZTERM_CONFIG/"
        success_msg "Wezterm configuration installed"
    else
        info_msg "Wezterm configuration already exists"
    fi
    
    success_msg "Wezterm setup completed"
    return 0
}

# Run the installation function
install_wezterm

