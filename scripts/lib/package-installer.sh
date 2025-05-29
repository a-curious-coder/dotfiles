#!/usr/bin/env bash

# Package Installation Library
# ============================
# Provides unified package installation functions

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/platform.sh"
source "$SCRIPT_DIR/logging.sh"

# Install package using appropriate method
install_package() {
    local package_name="$1"
    local config_file="$2"
    local platform="${3:-$(detect_platform)}"
    
    debug "Installing $package_name for $platform"
    
    # Read package configuration
    local package_config
    if ! package_config=$(yq eval ".packages.${package_name}" "$config_file" 2>/dev/null); then
        error "Package '$package_name' not found in configuration"
        return 1
    fi
    
    # Check if package configuration exists for platform
    local platform_config
    if platform_config=$(yq eval ".packages.${package_name}.${platform}" "$config_file" 2>/dev/null) && [[ "$platform_config" != "null" ]]; then
        debug "Using platform-specific configuration for $platform"
        install_package_with_config "$package_name" "$platform_config" "$platform"
    elif platform_config=$(yq eval ".packages.${package_name}" "$config_file" 2>/dev/null) && [[ "$platform_config" != "null" ]]; then
        debug "Using generic configuration"
        install_package_with_config "$package_name" "$platform_config" "$platform"
    else
        warning "No configuration found for $package_name on $platform"
        return 1
    fi
}

# Install package with specific configuration
install_package_with_config() {
    local package_name="$1"
    local config="$2"
    local platform="$3"
    
    local install_method
    install_method=$(echo "$config" | yq eval '.install_method' -)
    
    case "$install_method" in
        "apt")
            install_with_apt "$package_name" "$config"
            ;;
        "brew")
            install_with_brew "$package_name" "$config"
            ;;
        "cask")
            install_with_cask "$package_name" "$config"
            ;;
        "snap")
            install_with_snap "$package_name" "$config"
            ;;
        "script")
            install_with_script "$package_name" "$config"
            ;;
        *)
            warning "Unknown install method: $install_method"
            return 1
            ;;
    esac
}# Install methods for different package managers
install_with_apt() {
    local package_name="$1"
    local config="$2"
    
    local package
    package=$(echo "$config" | yq eval '.package' -)
    
    info "Installing $package_name via APT..."
    if sudo apt-get update && sudo apt-get install -y "$package"; then
        success "Successfully installed $package_name"
    else
        error "Failed to install $package_name"
        return 1
    fi
}

install_with_brew() {
    local package_name="$1"
    local config="$2"
    
    local package
    package=$(echo "$config" | yq eval '.package' -)
    
    info "Installing $package_name via Homebrew..."
    if brew install "$package"; then
        success "Successfully installed $package_name"
    else
        error "Failed to install $package_name"
        return 1
    fi
}

install_with_cask() {
    local package_name="$1"
    local config="$2"
    
    local package
    package=$(echo "$config" | yq eval '.package' -)
    
    info "Installing $package_name via Homebrew Cask..."
    if brew install --cask "$package"; then
        success "Successfully installed $package_name"
    else
        error "Failed to install $package_name"
        return 1
    fi
}

install_with_snap() {
    local package_name="$1"
    local config="$2"
    
    local package
    package=$(echo "$config" | yq eval '.package' -)
    
    info "Installing $package_name via Snap..."
    if sudo snap install "$package"; then
        success "Successfully installed $package_name"
    else
        error "Failed to install $package_name"
        return 1
    fi
}