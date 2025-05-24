#!/usr/bin/env bash

# Test Script for Dotfiles Setup
# ==============================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[TEST]${NC} $1"; }
success() { echo -e "${GREEN}[PASS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[FAIL]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test script syntax
test_script_syntax() {
    info "Testing script syntax..."

    local scripts=("install.sh" "scripts/install-packages.sh" "scripts/setup-dotfiles.sh" "scripts/post-install.sh")

    for script in "${scripts[@]}"; do
        if bash -n "$DOTFILES_DIR/$script"; then
            success "Syntax check passed: $script"
        else
            error "Syntax error in: $script"
            return 1
        fi
    done
}

# Test YAML configuration
test_yaml_config() {
    info "Testing YAML configuration..."

    if command -v yq &> /dev/null; then
        if yq eval '.packages | length' "$DOTFILES_DIR/config.yaml" > /dev/null; then
            local package_count=$(yq eval '.packages | length' "$DOTFILES_DIR/config.yaml")
            success "YAML config valid with $package_count packages"
        else
            error "Invalid YAML configuration"
            return 1
        fi
    else
        warning "yq not installed, skipping YAML validation"
    fi
}

# Test directory structure
test_directory_structure() {
    info "Testing directory structure..."

    local required_dirs=("scripts" "zsh" "git" "ghostty" "tmux")
    local required_files=("install.sh" "config.yaml" ".stowrc")

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$DOTFILES_DIR/$dir" ]]; then
            success "Directory exists: $dir"
        else
            error "Missing directory: $dir"
            return 1
        fi
    done

    for file in "${required_files[@]}"; do
        if [[ -f "$DOTFILES_DIR/$file" ]]; then
            success "File exists: $file"
        else
            error "Missing file: $file"
            return 1
        fi
    done
}

# Test configuration files
test_config_files() {
    info "Testing configuration files..."

    local config_files=(
        "zsh/.zshrc"
        "zsh/.zsh_aliases"
        "zsh/.zsh_functions"
        "git/.gitconfig"
        "ghostty/.config/ghostty/config"
    )

    for config in "${config_files[@]}"; do
        if [[ -f "$DOTFILES_DIR/$config" ]]; then
            success "Config file exists: $config"
        else
            error "Missing config file: $config"
            return 1
        fi
    done
}

# Main test execution
main() {
    echo -e "${BLUE}"
    echo "🧪 Testing Dotfiles Setup"
    echo "========================="
    echo -e "${NC}"

    test_directory_structure
    test_config_files
    test_script_syntax
    test_yaml_config

    echo ""
    success "🎉 All tests passed! Your dotfiles setup is ready."
    info "Run './install.sh' to install your development environment."
}

main "$@"
