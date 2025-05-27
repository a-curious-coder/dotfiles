#!/usr/bin/env bash

# Test script for Burp Suite installation
# =======================================

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

# Source the install function from the main script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/install-packages.sh"

# Test Burp Suite installation
main() {
    info "Testing Burp Suite installation..."
    
    # Check if already installed
    if command -v burpsuite &> /dev/null; then
        info "Burp Suite is already installed at: $(which burpsuite)"
        info "Version info:"
        burpsuite --version 2>/dev/null || info "Version information not available"
        
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping installation"
            return 0
        fi
    fi
    
    # Run the installation
    install_burpsuite
    
    # Test the installation
    info "Testing installation..."
    if command -v burpsuite &> /dev/null; then
        success "Burp Suite is accessible from PATH"
        info "Location: $(which burpsuite)"
        
        # Check if it's executable
        if [[ -x "$(which burpsuite)" ]]; then
            success "Burp Suite binary is executable"
        else
            warning "Burp Suite binary is not executable"
        fi
    else
        error "Burp Suite is not accessible from PATH"
        
        # Check if it exists in /opt
        if [[ -d "/opt/burpsuite" ]]; then
            info "Found Burp Suite directory: /opt/burpsuite"
            info "Contents:"
            ls -la /opt/burpsuite/ || true
        fi
    fi
}

main "$@"