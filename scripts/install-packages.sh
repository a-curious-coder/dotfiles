#!/usr/bin/env bash

# Package Installation Script
# ===========================

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
CONFIG_FILE="${DOTFILES_DIR}/config.yaml"

# Install yq for YAML parsing if not present
install_yq() {
    if ! command -v yq &> /dev/null; then
        info "Installing yq for YAML parsing..."
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
    fi
}

# Install package via APT
install_apt_package() {
    local name="$1"
    local package="$2"
    local repository="${3:-}"
    local key="${4:-}"

    if [[ -n "$repository" ]]; then
        if [[ -n "$key" ]]; then
            curl -fsSL "$key" | sudo apt-key add -
        fi
        echo "deb $repository stable main" | sudo tee /etc/apt/sources.list.d/${name}.list
        sudo apt update
    fi

    sudo apt install -y "$package"
}

# Install package via snap
install_snap_package() {
    local package="$1"
    sudo snap install "$package"
}

# Install package via script
install_script_package() {
    local url="$1"
    local args="${2:-}"

    if [[ -n "$args" ]]; then
        curl -fsSL "$url" | bash -s -- "$args"
    else
        curl -fsSL "$url" | bash
    fi
}

# Install binary package
install_binary_package() {
    local url="$1"
    local extract_to="$2"
    local binary_name="${3:-}"
    local install_to="${4:-/usr/local/bin/}"
    local temp_dir=$(mktemp -d)

    info "Downloading $url..."
    wget -q "$url" -O "${temp_dir}/package.tar.gz"

    info "Extracting to $extract_to..."
    mkdir -p "$extract_to"
    tar -xzf "${temp_dir}/package.tar.gz" -C "$extract_to"

    if [[ -n "$binary_name" ]]; then
        sudo cp "${extract_to}/${binary_name}" "$install_to"
        sudo chmod +x "${install_to}/${binary_name}"
    else
        # Copy all executables
        find "$extract_to" -type f -executable -exec sudo cp {} "$install_to" \;
        sudo chmod +x "${install_to}"/*
    fi

    rm -rf "$temp_dir"
}

# Install AppImage
install_appimage_package() {
    local url="$1"
    local install_to="$2"

    sudo wget -q "$url" -O "$install_to"
    sudo chmod +x "$install_to"
}

# Process each package from config
process_packages() {
    install_yq

    # Get package names from config
    local packages=$(yq eval '.packages | keys | .[]' "$CONFIG_FILE")

    while IFS= read -r package; do
        if [[ -z "$package" ]]; then continue; fi

        local name=$(yq eval ".packages.${package}.name" "$CONFIG_FILE")
        local install_method=$(yq eval ".packages.${package}.install_method" "$CONFIG_FILE")
        local verify_command=$(yq eval ".packages.${package}.verify_command" "$CONFIG_FILE")

        # Check if already installed
        if eval "$verify_command" &> /dev/null; then
            success "$name is already installed"
            continue
        fi

        info "Installing $name..."

        case "$install_method" in
            "apt")
                local pkg=$(yq eval ".packages.${package}.package" "$CONFIG_FILE")
                local repo=$(yq eval ".packages.${package}.repository" "$CONFIG_FILE" 2>/dev/null || echo "")
                local key=$(yq eval ".packages.${package}.key" "$CONFIG_FILE" 2>/dev/null || echo "")
                install_apt_package "$package" "$pkg" "$repo" "$key"
                ;;
            "snap")
                local pkg=$(yq eval ".packages.${package}.package" "$CONFIG_FILE")
                install_snap_package "$pkg"
                ;;
            "script")
                local url=$(yq eval ".packages.${package}.url" "$CONFIG_FILE")
                local script_args=$(yq eval ".packages.${package}.script_args" "$CONFIG_FILE" 2>/dev/null || echo "")
                install_script_package "$url" "$script_args"
                ;;
            "binary")
                local url=$(yq eval ".packages.${package}.url" "$CONFIG_FILE")
                local extract_to=$(yq eval ".packages.${package}.extract_to" "$CONFIG_FILE")
                local binary_name=$(yq eval ".packages.${package}.binary_name" "$CONFIG_FILE" 2>/dev/null || echo "")
                local install_to=$(yq eval ".packages.${package}.install_to" "$CONFIG_FILE" 2>/dev/null || echo "/usr/local/bin/")
                install_binary_package "$url" "$extract_to" "$binary_name" "$install_to"
                ;;
            "appimage")
                local url=$(yq eval ".packages.${package}.url" "$CONFIG_FILE")
                local install_to=$(yq eval ".packages.${package}.install_to" "$CONFIG_FILE")
                install_appimage_package "$url" "$install_to"
                ;;
        esac

        # Run post-install commands
        local post_install_commands=$(yq eval ".packages.${package}.post_install[]?" "$CONFIG_FILE" 2>/dev/null || echo "")
        if [[ -n "$post_install_commands" && "$post_install_commands" != "null" ]]; then
            while IFS= read -r cmd; do
                if [[ -n "$cmd" && "$cmd" != "null" ]]; then
                    info "Running post-install: $cmd"
                    eval "$cmd" || warning "Post-install command failed: $cmd"
                fi
            done <<< "$post_install_commands"
        fi

        # Verify installation
        if eval "$verify_command" &> /dev/null; then
            success "$name installed successfully"
        else
            error "Failed to install $name"
        fi

    done <<< "$packages"
}

# Install Oh My Zsh and plugins
install_oh_my_zsh() {
    info "Installing Oh My Zsh..."

    # Install Oh My Zsh if not present
    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed"
    else
        success "Oh My Zsh already installed"
    fi

    # Install plugins
    local plugins=$(yq eval '.zsh_plugins[]' "$CONFIG_FILE")
    while IFS= read -r plugin; do
        if [[ -z "$plugin" ]]; then continue; fi

        case "$plugin" in
            "zsh-autosuggestions")
                if [[ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
                    info "Installing zsh-autosuggestions..."
                    git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
                fi
                ;;
            "zsh-syntax-highlighting")
                if [[ ! -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
                    info "Installing zsh-syntax-highlighting..."
                    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
                fi
                ;;
            "powerlevel10k")
                if [[ ! -d "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
                    info "Installing powerlevel10k theme..."
                    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k
                fi
                ;;
        esac
        success "$plugin plugin ready"
    done <<< "$plugins"
}

# Main execution
main() {
    info "Starting package installation..."
    process_packages
    install_oh_my_zsh
    success "All packages installed successfully!"
}

main "$@"
