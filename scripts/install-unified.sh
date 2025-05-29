#!/usr/bin/env bash

# Unified Dotfiles Installation Script
# ====================================
# Single script for all platforms and installation modes

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Import shared functions
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/platform.sh"
source "${SCRIPT_DIR}/lib/packages.sh"

# Installation modes
INSTALL_MODE="full"        # full, dotfiles-only, packages-only
INTERACTIVE_MODE=false     # Interactive package selection
DRY_RUN=false             # Show what would be done
FORCE_REINSTALL=false     # Reinstall already installed packages
SELECTED_CATEGORIES=()    # Specific categories to install

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --dotfiles-only)
                INSTALL_MODE="dotfiles-only"
                shift
                ;;
            --packages-only)
                INSTALL_MODE="packages-only"
                shift
                ;;
            --interactive|-i)
                INTERACTIVE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_REINSTALL=true
                shift
                ;;
            --categories)
                shift
                if [[ $# -gt 0 ]]; then
                    IFS=',' read -ra SELECTED_CATEGORIES <<< "$1"
                    shift
                else
                    error "--categories requires a comma-separated list"
                    exit 1
                fi
                ;;
            --list-categories)
                show_package_info
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << EOF
Unified Dotfiles Installation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    --dotfiles-only         Install dotfiles configuration only
    --packages-only         Install packages only
    -i, --interactive       Interactive package selection
    --categories LIST       Install specific categories (comma-separated)
    --list-categories       Show available categories and packages
    --dry-run              Show what would be installed
    --force                Force reinstall of existing packages

EXAMPLES:
    $0                      # Full installation
    $0 --interactive        # Choose what to install
    $0 --dotfiles-only      # Just link configurations
    $0 --categories "essential,development"  # Install specific categories
    $0 --list-categories    # Show available packages
    $0 --dry-run            # Preview installation

SUPPORTED PLATFORMS:
    • Linux (Ubuntu/Debian, Fedora/RHEL, Arch)
    • macOS (Homebrew)

For more information, see the README.md file.
EOF
}

# Install specific categories
install_selected_categories() {
    local platform=$(detect_platform)
    local failed_categories=()
    
    for category in "${SELECTED_CATEGORIES[@]}"; do
        # Trim whitespace
        category=$(echo "$category" | tr -d ' ')
        
        if install_category "$category" "$platform"; then
            success "Category '$category' completed successfully"
        else
            error "Category '$category' had failures"
            failed_categories+=("$category")
        fi
    done
    
    if [[ ${#failed_categories[@]} -gt 0 ]]; then
        warning "Categories with failures: ${failed_categories[*]}"
        return 1
    fi
    
    success "Selected categories installation complete"
}

# Main installation flow
main() {
    header "🚀 Unified Dotfiles Installation"
    
    # Validate environment
    validate_platform
    validate_config
    
    # Show dry-run information
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN MODE - No changes will be made"
        echo
        show_package_info
        return 0
    fi
    
    case "$INSTALL_MODE" in
        "full")
            install_dependencies
            if [[ ${#SELECTED_CATEGORIES[@]} -gt 0 ]]; then
                install_selected_categories
            elif [[ "$INTERACTIVE_MODE" == "true" ]]; then
                interactive_package_selection
            else
                install_all_packages
            fi
            setup_dotfiles
            setup_shell
            ;;
        "dotfiles-only")
            setup_dotfiles
            setup_shell
            ;;
        "packages-only")
            install_dependencies
            if [[ ${#SELECTED_CATEGORIES[@]} -gt 0 ]]; then
                install_selected_categories
            elif [[ "$INTERACTIVE_MODE" == "true" ]]; then
                interactive_package_selection
            else
                install_all_packages
            fi
            ;;
    esac
    
    post_install_cleanup
    show_completion_message
}

parse_arguments "$@"
main
