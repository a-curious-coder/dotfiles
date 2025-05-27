#!/usr/bin/env bash

# Dotfiles Installation Script
# ============================
# One command to rule them all!

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "${PURPLE}[HEADER]${NC} $1"; }

# Get script directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${DOTFILES_DIR}/scripts"

# Installation mode selection
show_installation_menu() {
    echo -e "${YELLOW}🚀 Choose Installation Mode:${NC}"
    echo ""
    echo -e "${BLUE}[1]${NC} 🔄 Full Install - Install everything (recommended)"
    echo -e "${BLUE}[2]${NC} ⚙️  Dotfiles Only - Just configure shell/editor, no packages"
    echo -e "${BLUE}[q]${NC} ❌ Quit"
    echo ""
    echo -n "Select installation mode: "
    read -r mode_choice

    case "$mode_choice" in
        "1")
            info "Starting full installation..."
            return 0  # Continue with original script
            ;;
        "2")
            info "Setting up dotfiles only..."
            setup_dotfiles_only
            exit 0
            ;;
        "q"|"Q")
            info "Installation cancelled. Goodbye! 👋"
            exit 0
            ;;
        *)
            warning "Invalid choice. Using Full Install..."
            return 0
            ;;
    esac
}

# Setup dotfiles without installing packages
setup_dotfiles_only() {
    header "🔧 Setting up dotfiles configuration..."

    # Run dotfiles setup
    if [[ -f "${SCRIPTS_DIR}/setup-dotfiles.sh" ]]; then
        "${SCRIPTS_DIR}/setup-dotfiles.sh"
    else
        warning "Dotfiles setup script not found, using stow directly..."
        cd "$DOTFILES_DIR"

        # Stow all configurations
        for dir in */; do
            if [[ -d "$dir" && "$dir" != "scripts/" ]]; then
                stow "${dir%/}" 2>/dev/null || true
            fi
        done
    fi

    success "Dotfiles setup complete! ✅"
    info "Your shell configuration is ready. Restart your terminal or run 'source ~/.zshrc'"
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║                   DOTFILES                       ║
║              Installation Script                 ║
║                                                  ║
║   🚀 Automated Development Environment Setup     ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if running on Linux
check_system() {
    header "Checking system compatibility..."

    if [[ "$(uname)" != "Linux" ]]; then
        error "This script is designed for Linux systems only"
        error "Current system: $(uname)"
        exit 1
    fi

    # Check if we have sudo access and prompt if needed
    if ! sudo -n true 2>/dev/null; then
        warning "This script requires sudo access for package installation"
        info "You may be prompted for your password..."

        if ! sudo -v; then
            error "Failed to obtain sudo access"
            exit 1
        fi
    fi

    success "System check passed: Linux detected with sudo access"
}

# Update system packages
update_system() {
    header "Updating system packages..."

    info "Updating package lists..."
    sudo apt update -y

    info "Upgrading installed packages..."
    sudo apt upgrade -y

    info "Installing essential dependencies..."
    sudo apt install -y curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release

    success "System update completed"
}

# Install packages
install_packages() {
    header "Installing software packages..."

    if [[ -x "${SCRIPTS_DIR}/install-packages.sh" ]]; then
        bash "${SCRIPTS_DIR}/install-packages.sh"
        success "Package installation completed"
    else
        error "Package installation script not found or not executable"
        exit 1
    fi
}

# Setup dotfiles
setup_dotfiles() {
    header "Setting up configuration files..."

    if [[ -x "${SCRIPTS_DIR}/setup-dotfiles.sh" ]]; then
        bash "${SCRIPTS_DIR}/setup-dotfiles.sh"
        success "Dotfiles setup completed"
    else
        error "Dotfiles setup script not found or not executable"
        exit 1
    fi
}

# Run post-installation tasks
post_install() {
    header "Running post-installation tasks..."

    if [[ -x "${SCRIPTS_DIR}/post-install.sh" ]]; then
        bash "${SCRIPTS_DIR}/post-install.sh"
        success "Post-installation completed"
    else
        error "Post-installation script not found or not executable"
        exit 1
    fi
}

# Make scripts executable
setup_scripts() {
    info "Making scripts executable..."
    find "$SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \;
    success "Scripts are now executable"
}

# Cleanup
cleanup() {
    header "Cleaning up..."

    info "Cleaning package cache..."
    sudo apt autoremove -y
    sudo apt autoclean

    success "Cleanup completed"
}

# Final instructions
show_final_instructions() {
    echo -e "${CYAN}"
    cat << "EOF"

╔══════════════════════════════════════════════════╗
║                  🎉 SUCCESS! 🎉                  ║
║                                                  ║
║        Your development environment is           ║
║              ready to rock! 🚀                   ║
╚══════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    success "Installation completed successfully!"
    echo ""
    info "🔄 Please restart your terminal or run: source ~/.zshrc"
    info "🐳 Docker group added - you may need to log out/in for changes to take effect"
    info "⚙️  Customize your configurations in ~/.config/"
    echo ""
    info "Installed tools:"
    info "  • Ghostty terminal with custom shaders"
    info "  • Zsh with Oh My Zsh and Powerlevel10k"
    info "  • Neovim, tmux, and modern CLI tools"
    info "  • Docker, LazyDocker, LazyGit"
    info "  • VS Code with extensions"
    info "  • Go, Rust, Node.js development environments"
    echo ""
    info "Quick commands to try:"
    info "  • lazydocker  - Docker container management"
    info "  • lazygit     - Git repository management"
    info "  • nvim        - Modern text editor"
    info "  • lsd         - Modern ls with colors"
    info "  • bat         - Modern cat with syntax highlighting"
    echo ""
    success "Happy coding! 💻✨"
}

# Error handling
handle_error() {
    error "An error occurred during installation"
    error "Check the output above for details"
    exit 1
}

# Set error trap
trap handle_error ERR

# Main execution
# Main installation function
main() {
    show_banner

    # Show installation mode selection
    show_installation_menu

    # If we reach here, user chose Classic Mode
    check_system
    setup_scripts
    update_system
    install_packages
    setup_dotfiles
    post_install
    cleanup
    show_final_instructions
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
