#!/usr/bin/env bash

# Cross-Platform Dotfiles Installation Script
# ===========================================
# Supports both Linux and macOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        *)          echo "unknown";;
    esac
}

# Display header with OS detection
header() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║   🚀 Cross-Platform Development Environment     ║
║         Modern Dotfiles Installation             ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local os="$(detect_os)"
    local os_name
    case "$os" in
        linux) os_name="Linux" ;;
        macos) os_name="macOS" ;;
        *) os_name="Unknown ($os)" ;;
    esac
    
    info "Detected Operating System: $os_name"
    echo ""
}

# Check system compatibility and requirements
check_system() {
    local os="$(detect_os)"
    
    header "Checking system compatibility..."

    case "$os" in
        linux)
            if [[ ! -f /etc/os-release ]]; then
                error "Cannot detect Linux distribution"
                exit 1
            fi
            
            # Check for sudo access
            if ! sudo -n true 2>/dev/null; then
                warning "This script requires sudo access for package installation"
                info "You may be prompted for your password..."
                
                if ! sudo -v; then
                    error "Failed to obtain sudo access"
                    exit 1
                fi
            fi
            
            success "Linux system check passed with sudo access"
            ;;
            
        macos)
            # Check for basic requirements
            if ! command -v curl >/dev/null 2>&1; then
                error "curl is required but not installed. Please install curl first."
                exit 1
            fi
            
            # Check macOS version
            local macos_version
            macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            info "macOS Version: $macos_version"
            
            # Warn about potential permission requirements
            warning "Some installations may require administrator password"
            warning "GUI applications may open during installation"
            
            success "macOS system check passed"
            ;;
            
        *)
            error "Unsupported operating system: $os"
            error "This script supports Linux and macOS only"
            exit 1
            ;;
    esac
}

# Update system packages
update_system() {
    local os="$(detect_os)"
    
    header "Updating system packages..."

    case "$os" in
        linux)
            info "Updating APT package lists..."
            sudo apt update -y
            sudo apt upgrade -y
            ;;
        macos)
            # Check if Homebrew is installed, if not, install it
            if ! command -v brew >/dev/null 2>&1; then
                info "Installing Homebrew package manager..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH
                eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
            fi
            
            info "Updating Homebrew..."
            brew update
            brew upgrade
            ;;
    esac

    success "System packages updated"
}

# Install essential dependencies
install_dependencies() {
    local os="$(detect_os)"
    
    header "Installing essential dependencies..."

    case "$os" in
        linux)
            info "Installing essential packages..."
            sudo apt install -y curl wget git unzip software-properties-common apt-transport-https
            ;;
        macos)
            info "Installing essential packages..."
            # Install Xcode Command Line Tools if needed
            if ! xcode-select -p >/dev/null 2>&1; then
                info "Installing Xcode Command Line Tools..."
                xcode-select --install
                echo "Please complete the Xcode Command Line Tools installation and press Enter to continue..."
                read -r
            fi
            
            # Install essential tools via Homebrew
            brew install curl wget git unzip
            ;;
    esac

    success "Essential dependencies installed"
}

# Setup dotfiles with Stow
setup_dotfiles() {
    header "Setting up configuration files..."

    # Install GNU Stow if not present
    local os="$(detect_os)"
    if ! command -v stow >/dev/null 2>&1; then
        info "Installing GNU Stow..."
        case "$os" in
            linux)
                sudo apt install -y stow
                ;;
            macos)
                brew install stow
                ;;
        esac
    fi

    cd "$DOTFILES_DIR"

    # Backup existing dotfiles
    local backup_dir="${HOME}/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
        info "Backing up existing dotfiles to $backup_dir"
        mkdir -p "$backup_dir"
        mv "${HOME}/.zshrc" "$backup_dir/" 2>/dev/null || true
        mv "${HOME}/.gitconfig" "$backup_dir/" 2>/dev/null || true
        mv "${HOME}/.tmux.conf" "$backup_dir/" 2>/dev/null || true
    fi

    # Create necessary directories
    mkdir -p "${HOME}/.config"

    # Stow the configuration files
    local stow_dirs=("zsh" "git" "ghostty" "nvim" "tmux" "vscode")
    for dir in "${stow_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "Stowing $dir configurations..."
            stow -v -t "$HOME" "$dir" || warning "Issues stowing $dir"
            success "$dir configurations linked"
        fi
    done

    success "Dotfiles setup completed"
}

# Install packages based on OS
install_packages() {
    header "Installing development and security tools..."

    # Run the package installation script
    if [[ -f "${DOTFILES_DIR}/scripts/install-packages.sh" ]]; then
        bash "${DOTFILES_DIR}/scripts/install-packages.sh"
    else
        warning "Package installation script not found, skipping package installation"
    fi
}

# Setup shell environment
setup_shell() {
    local os="$(detect_os)"
    
    header "Setting up shell environment..."

    # Install Oh My Zsh if not present
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Changing default shell to zsh..."
        local zsh_path
        case "$os" in
            linux)
                zsh_path="$(which zsh)"
                ;;
            macos)
                zsh_path="/opt/homebrew/bin/zsh"
                [[ ! -f "$zsh_path" ]] && zsh_path="/usr/local/bin/zsh"
                [[ ! -f "$zsh_path" ]] && zsh_path="$(which zsh)"
                ;;
        esac
        
        if [[ -n "$zsh_path" && -f "$zsh_path" ]]; then
            chsh -s "$zsh_path"
            success "Default shell changed to zsh"
        else
            warning "Could not find zsh executable"
        fi
    fi

    success "Shell environment setup completed"
}

# Post-installation setup
post_install() {
    header "Running post-installation setup..."

    # Run post-install script if it exists
    if [[ -f "${DOTFILES_DIR}/scripts/post-install.sh" ]]; then
        bash "${DOTFILES_DIR}/scripts/post-install.sh"
    fi

    success "Post-installation setup completed"
}

# Display completion message
completion_message() {
    echo ""
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║              🎉 Installation Complete!           ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo -e "${GREEN}Your development environment is now ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: exec zsh"
    echo "2. Configure Git credentials: ./scripts/setup-git-user.sh"
    echo "3. See installed tools: show-tools"
    echo "4. Start a new project workspace!"
    echo ""
    
    local os="$(detect_os)"
    case "$os" in
        linux)
            echo "Linux-specific notes:"
            echo "• Some GUI applications may require logout/login"
            echo "• Docker requires adding user to docker group (done automatically)"
            ;;
        macos)
            echo "macOS-specific notes:"
            echo "• Some applications may be in /Applications folder"
            echo "• Homebrew installed tools are in /opt/homebrew/bin"
            echo "• You may need to approve security dialogs for some apps"
            ;;
    esac
}

# Error handling
trap 'error "Installation failed! Check the output above for details."' ERR

# Main installation flow
main() {
    # Check system compatibility
    check_system

    # Update system
    update_system

    # Install dependencies
    install_dependencies

    # Setup dotfiles
    setup_dotfiles

    # Install packages
    install_packages

    # Setup shell
    setup_shell

    # Post-installation
    post_install

    # Show completion message
    completion_message
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Cross-Platform Dotfiles Installation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --dotfiles     Install dotfiles only (skip packages)"
        echo "  --packages     Install packages only (skip dotfiles)"
        echo ""
        echo "Supported platforms: Linux (Ubuntu/Debian), macOS"
        exit 0
        ;;
    --dotfiles)
        check_system
        install_dependencies
        setup_dotfiles
        setup_shell
        completion_message
        ;;
    --packages)
        check_system
        install_dependencies
        install_packages
        post_install
        completion_message
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
