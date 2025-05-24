#!/usr/bin/env bash

# Dotfiles Setup Script
# =====================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Backup existing dotfiles
backup_dotfiles() {
    local backup_dir="${HOME}/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

    info "Creating backup directory at $backup_dir"
    mkdir -p "$backup_dir"

    # List of common dotfiles that might conflict
    local dotfiles=(".zshrc" ".gitconfig" ".tmux.conf")

    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "${HOME}/${dotfile}" && ! -L "${HOME}/${dotfile}" ]]; then
            info "Backing up existing $dotfile"
            mv "${HOME}/${dotfile}" "$backup_dir/"
        fi
    done

    # Backup existing config directories
    local config_dirs=("ghostty" "nvim" "Code")
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "${HOME}/.config/${config_dir}" && ! -L "${HOME}/.config/${config_dir}" ]]; then
            info "Backing up existing .config/$config_dir"
            mv "${HOME}/.config/${config_dir}" "$backup_dir/"
        fi
    done

    success "Backup completed"
}

# Setup dotfiles with Stow
setup_stow_packages() {
    info "Setting up configuration files with Stow..."

    cd "$DOTFILES_DIR"

    # List of directories to stow (excluding utility directories)
    local stow_dirs=("zsh" "git" "ghostty" "nvim" "tmux")

    for dir in "${stow_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Stowing $dir configurations..."
            stow -v -t "$HOME" "$dir" || warning "Issues stowing $dir"
            success "$dir configurations linked"
        else
            warning "Directory $dir not found, skipping..."
        fi
    done

    # Handle VS Code separately (different target)
    if [[ -d "vscode" ]]; then
        info "Stowing VS Code configurations..."
        stow -v -t "$HOME" vscode || warning "Issues stowing vscode"
        success "VS Code configurations linked"
    fi
}

# Create necessary directories
create_directories() {
    info "Creating necessary directories..."

    # Ensure .config directory exists
    mkdir -p "${HOME}/.config"

    # Create directories for development
    mkdir -p "${HOME}/dev"
    mkdir -p "${HOME}/.local/bin"

    success "Directories created"
}

# Set proper permissions
fix_permissions() {
    info "Setting proper permissions..."

    # Make sure user owns their home directory files
    sudo chown -R $(whoami):$(whoami) "$HOME/.config" 2>/dev/null || true

    # Make scripts executable
    find "$DOTFILES_DIR" -name "*.sh" -exec chmod +x {} \;

    success "Permissions set"
}

# Main execution
main() {
    info "Starting dotfiles setup..."

    backup_dotfiles
    create_directories
    setup_stow_packages
    fix_permissions

    success "Dotfiles setup completed!"
    info "Configuration files have been symlinked to your home directory"
}

main "$@"
