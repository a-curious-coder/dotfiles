#!/usr/bin/env bash

# Main setup script for dotfiles
# ------------------------------

# Source utility functions
source "$(dirname "$0")/utils/colors.sh"
source "$(dirname "$0")/utils/os_detection.sh"

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Create backup directory if needed
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    info_msg "Created backup directory at $BACKUP_DIR"
fi

# Check for stow
if ! command -v stow >/dev/null 2>&1; then
    info_msg "Installing stow..."
    if is_macos; then
        brew install stow
    elif is_ubuntu; then
        sudo apt-get update && sudo apt-get install -y stow
    else
        error_msg "Unsupported OS for automatic stow installation"
        exit 1
    fi
    success_msg "Stow installed successfully"
fi

# Determine if we're on a server
is_server() {
    # Simple heuristic - servers typically don't have display
    [ -z "$DISPLAY" ] && [ "$XDG_SESSION_TYPE" != "wayland" ] && ! is_macos
}

# Run installation scripts
info_msg "Running installation scripts..."
for installer in */install.sh; do
    dir_name=$(dirname "$installer")

    # Skip GUI applications on servers
    if is_server && [[ "$dir_name" == "wezterm" || "$dir_name" == "other-gui-app" ]]; then
        info_msg "Skipping $dir_name on server environment"
        continue
    fi

    info_msg "Setting up $dir_name..."
    bash "$installer"
    if [ $? -eq 0 ]; then
        success_msg "$dir_name setup completed"
    else
        warning_msg "$dir_name setup encountered issues"
    fi
done

# Stow configurations
info_msg "Symlinking configuration files with stow..."
for dir in */; do
    dir_name=$(basename "$dir")
    # Skip utility directories
    if [[ "$dir_name" != "utils" && "$dir_name" != "core" ]]; then
        info_msg "Stowing $dir_name configurations..."
        cd "$DOTFILES_DIR"
        stow -v -t "$HOME" "$dir_name"
        if [ $? -eq 0 ]; then
            success_msg "$dir_name configurations linked"
        else
            warning_msg "Issues linking $dir_name configurations"
        fi
    fi
done

success_msg "Dotfiles setup completed! 🎉"
info_msg "You may need to restart your shell to apply all changes."

