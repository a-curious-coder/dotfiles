#!/usr/bin/env bash

# Common Utilities Library
# ========================
# Shared functions used across installation scripts

# Source other libraries
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/platform.sh"

# Configuration
readonly DOTFILES_DIR="$(cd "$LIB_DIR/../.." && pwd)"
readonly CONFIG_FILE="$DOTFILES_DIR/packages.yaml"
readonly STOW_DIR="$DOTFILES_DIR"

# Validate prerequisites
validate_platform() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|macos)
            info "Detected platform: $platform"
            ;;
        *)
            error "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

# Check if configuration file exists
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    if ! command -v yq &> /dev/null; then
        error "yq is required but not installed. Please install yq first."
        exit 1
    fi
}

# Install system dependencies (package managers, etc.)
install_dependencies() {
    local platform=$(detect_platform)
    
    info "Installing system dependencies..."
    
    case "$platform" in
        macos)
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                info "Homebrew already installed"
            fi
            ;;
        linux)
            local distro=$(get_linux_distro)
            case "$distro" in
                ubuntu|debian)
                    sudo apt update
                    sudo apt install -y curl wget git
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y curl wget git
                    ;;
                arch|manjaro)
                    sudo pacman -Sy --noconfirm curl wget git
                    ;;
            esac
            ;;
    esac
    
    # Install yq if not present
    if ! command_exists yq; then
        info "Installing yq..."
        case "$platform" in
            macos)
                brew install yq
                ;;
            linux)
                local distro=$(get_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        sudo snap install yq
                        ;;
                    *)
                        # Fallback to binary installation
                        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
                        sudo chmod +x /usr/local/bin/yq
                        ;;
                esac
                ;;
        esac
    fi
}

# Setup dotfiles using GNU Stow
setup_dotfiles() {
    info "Setting up dotfiles..."
    
    # Install stow if not present
    if ! command_exists stow; then
        info "Installing GNU Stow..."
        local platform=$(detect_platform)
        case "$platform" in
            macos)
                brew install stow
                ;;
            linux)
                local distro=$(get_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        sudo apt install -y stow
                        ;;
                    fedora|rhel|centos)
                        sudo dnf install -y stow
                        ;;
                    arch|manjaro)
                        sudo pacman -S --noconfirm stow
                        ;;
                esac
                ;;
        esac
    fi
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR" || exit 1
    
    # Get list of stowable directories
    local stow_dirs
    mapfile -t stow_dirs < <(find . -maxdepth 1 -type d -name ".*" -not -name ".git*" -not -name ".." -not -name "." | sed 's|./||')
    
    if [[ ${#stow_dirs[@]} -eq 0 ]]; then
        warning "No stowable directories found"
        return
    fi
    
    info "Stowing configurations..."
    for dir in "${stow_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            info "  Stowing $dir"
            stow -v "$dir" 2>/dev/null || warning "Failed to stow $dir"
        fi
    done
    
    success "Dotfiles setup complete"
}

# Setup shell configuration
setup_shell() {
    info "Setting up shell configuration..."
    
    # Check if zsh is installed
    if ! command_exists zsh; then
        info "Installing zsh..."
        local platform=$(detect_platform)
        case "$platform" in
            macos)
                brew install zsh
                ;;
            linux)
                local distro=$(get_linux_distro)
                case "$distro" in
                    ubuntu|debian)
                        sudo apt install -y zsh
                        ;;
                    fedora|rhel|centos)
                        sudo dnf install -y zsh
                        ;;
                    arch|manjaro)
                        sudo pacman -S --noconfirm zsh
                        ;;
                esac
                ;;
        esac
    fi
    
    # Change default shell to zsh if not already
    if [[ "$SHELL" != *"zsh" ]]; then
        info "Changing default shell to zsh..."
        local zsh_path=$(which zsh)
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        chsh -s "$zsh_path"
        info "Shell changed to zsh. Please restart your terminal."
    fi
    
    success "Shell setup complete"
}

# Post-installation cleanup
post_install_cleanup() {
    info "Running post-installation cleanup..."
    
    # Update shell completions
    if command_exists brew; then
        brew cleanup &> /dev/null || true
    fi
    
    # Reload shell configuration if possible
    if [[ -f "$HOME/.zshrc" ]]; then
        info "Shell configuration updated. Run 'source ~/.zshrc' or restart your terminal."
    fi
    
    success "Cleanup complete"
}

# Show completion message
show_completion_message() {
    echo
    success "🎉 Dotfiles installation complete!"
    echo
    info "Next steps:"
    echo "  1. Restart your terminal or run 'source ~/.zshrc'"
    echo "  2. Verify configurations are working correctly"
    echo "  3. Customize settings as needed"
    echo
}

# Print header with emoji
header() {
    echo
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo
}

# Export functions
export -f validate_platform
export -f validate_config
export -f install_dependencies
export -f setup_dotfiles
export -f setup_shell
export -f post_install_cleanup
export -f show_completion_message
export -f header
