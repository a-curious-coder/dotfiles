#!/usr/bin/env bash

# Git User Setup Script
# =====================
# Securely configure git user credentials in a local file
# that won't be committed to the repository

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

LOCAL_GITCONFIG="${HOME}/.gitconfig.local"

show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════╗
    ║              🔐 Git User Setup                       ║
    ║                                                      ║
    ║     Configure your personal git credentials          ║
    ║     (stored locally, not in the repository)         ║
    ╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if local config already exists
check_existing_config() {
    if [[ -f "$LOCAL_GITCONFIG" ]]; then
        echo -e "${YELLOW}Existing git configuration found:${NC}"
        echo ""
        cat "$LOCAL_GITCONFIG"
        echo ""
        
        echo -n "Do you want to update it? (y/N): "
        read -r update_choice
        
        if [[ ! "$update_choice" =~ ^[Yy]$ ]]; then
            info "Keeping existing configuration"
            exit 0
        fi
    fi
}

# Get user input for credentials
get_user_input() {
    echo -e "${BLUE}Enter your git configuration:${NC}"
    echo ""
    
    # Get name
    echo -n "Full name (e.g., John Doe): "
    read -r user_name
    
    # Get email
    echo -n "Email address: "
    read -r user_email
    
    # Optional: Get signing key
    echo ""
    echo -n "GPG signing key ID (optional, press Enter to skip): "
    read -r signing_key
    
    # Validate input
    if [[ -z "$user_name" || -z "$user_email" ]]; then
        error "Name and email are required!"
        exit 1
    fi
    
    # Validate email format
    if [[ ! "$user_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        error "Invalid email format!"
        exit 1
    fi
}

# Create the local gitconfig file
create_local_config() {
    info "Creating local git configuration..."
    
    cat > "$LOCAL_GITCONFIG" << EOF
# Personal Git Configuration
# This file is local only and not tracked in the repository

[user]
    name = $user_name
    email = $user_email
EOF

    # Add signing key if provided
    if [[ -n "$signing_key" ]]; then
        cat >> "$LOCAL_GITCONFIG" << EOF
    signingkey = $signing_key

[commit]
    gpgsign = true

[tag]
    gpgsign = true
EOF
    fi
    
    success "Local git configuration created!"
}

# Show final configuration
show_final_config() {
    echo ""
    info "Your git configuration:"
    echo ""
    git config --list | grep -E "(user\.|commit\.gpgsign|tag\.gpgsign)" || true
    echo ""
    
    success "Git user setup complete! 🎉"
    info "Your credentials are stored in: $LOCAL_GITCONFIG"
    info "This file is NOT tracked in your dotfiles repository"
}

# Add to gitignore if not already there
update_gitignore() {
    local gitignore_file="${HOME}/.dotfiles/.gitignore"
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f "$gitignore_file" ]]; then
        info "Creating .gitignore file..."
        touch "$gitignore_file"
    fi
    
    # Add .gitconfig.local to gitignore if not already there
    if ! grep -q "\.gitconfig\.local" "$gitignore_file" 2>/dev/null; then
        echo "" >> "$gitignore_file"
        echo "# Local git configuration (contains personal credentials)" >> "$gitignore_file"
        echo ".gitconfig.local" >> "$gitignore_file"
        info "Added .gitconfig.local to .gitignore"
    fi
}

# Main function
main() {
    show_banner
    check_existing_config
    get_user_input
    create_local_config
    update_gitignore
    show_final_config
}

main "$@"
