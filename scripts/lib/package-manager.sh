#!/usr/bin/env bash

# Package Manager Library
# =======================
# Unified package installation across platforms

# Import dependencies
source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"

# Install package using unified configuration
install_package() {
    local package_name="$1"
    local package_config="$2"
    local platform="$(detect_platform)"
    
    # Extract package info
    local name=$(echo "$package_config" | yq eval '.name' -)
    local description=$(echo "$package_config" | yq eval '.description // ""' -)
    
    # Check if package is already installed
    local verify_cmd=$(echo "$package_config" | yq eval '.verify' -)
    
    # Handle template variables in verify command
    verify_cmd=$(resolve_template_vars "$verify_cmd" "$package_config" "$platform")
    
    if [[ -n "$verify_cmd" && "$verify_cmd" != "null" ]] && eval "$verify_cmd" &>/dev/null; then
        success "$name is already installed"
        return 0
    fi
    
    info "Installing $name..."
    [[ -n "$description" && "$description" != "null" ]] && info "  $description"
    
    # Get platform-specific configuration
    local platform_config=$(echo "$package_config" | yq eval ".platforms.$platform" -)
    if [[ "$platform_config" == "null" ]]; then
        warning "$name not available for $platform"
        return 1
    fi
    
    # Extract installation method and parameters
    local method=$(echo "$platform_config" | yq eval '.method' -)
    local package=$(echo "$platform_config" | yq eval '.package // ""' -)
    
    # Install based on method
    case "$method" in
        "apt")
            install_apt_package "$package_name" "$platform_config"
            ;;
        "brew")
            install_brew_package "$package_name" "$platform_config"
            ;;
        "cask")
            install_cask_package "$package_name" "$platform_config"
            ;;
        "snap")
            install_snap_package "$package_name" "$platform_config"
            ;;
        "script")
            install_script_package "$package_name" "$platform_config"
            ;;
        "binary")
            install_binary_package "$package_name" "$platform_config"
            ;;
        *)
            error "Unknown installation method: $method"
            return 1
            ;;
    esac
    
    # Run post-install commands
    local post_install=$(echo "$platform_config" | yq eval '.post_install[]?' -)
    if [[ -n "$post_install" && "$post_install" != "null" ]]; then
        info "Running post-install commands..."
        while IFS= read -r cmd; do
            if [[ -n "$cmd" && "$cmd" != "null" ]]; then
                debug "Executing: $cmd"
                eval "$cmd" || warning "Post-install command failed: $cmd"
            fi
        done <<< "$post_install"
    fi
    
    # Verify installation
    if [[ -n "$verify_cmd" && "$verify_cmd" != "null" ]] && eval "$verify_cmd" &>/dev/null; then
        success "$name installed successfully"
    else
        error "Failed to verify $name installation"
        return 1
    fi
}

# Resolve template variables like {{binary_name}}
resolve_template_vars() {
    local template="$1"
    local package_config="$2"
    local platform="$3"
    
    # Get platform-specific config
    local platform_config=$(echo "$package_config" | yq eval ".platforms.$platform" -)
    
    # Replace {{binary_name}} with actual binary name
    local binary_name=$(echo "$platform_config" | yq eval '.binary_name // ""' -)
    if [[ -n "$binary_name" && "$binary_name" != "null" ]]; then
        template="${template//\{\{binary_name\}\}/$binary_name}"
    fi
    
    echo "$template"
}

# APT package installation
install_apt_package() {
    local name="$1"
    local config="$2"
    
    local package=$(echo "$config" | yq eval '.package' -)
    local repository=$(echo "$config" | yq eval '.repository' -)
    local key=$(echo "$config" | yq eval '.key' -)
    
    # Add repository if specified
    if [[ -n "$repository" && "$repository" != "null" ]]; then
        if [[ -n "$key" && "$key" != "null" ]]; then
            curl -fsSL "$key" | sudo apt-key add - 2>/dev/null || true
        fi
        echo "deb $repository stable main" | sudo tee "/etc/apt/sources.list.d/${name}.list" >/dev/null
        sudo apt update -qq
    fi
    
    sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq "$package"
}

# Homebrew formula installation
install_brew_package() {
    local name="$1"
    local config="$2"
    
    local package=$(echo "$config" | yq eval '.package' -)
    brew install "$package"
}

# Homebrew Cask installation
install_cask_package() {
    local name="$1"
    local config="$2"
    
    local package=$(echo "$config" | yq eval '.package' -)
    brew install --cask "$package"
}

# Snap package installation
install_snap_package() {
    local name="$1"
    local config="$2"
    
    local package=$(echo "$config" | yq eval '.package' -)
    sudo snap install "$package"
}

# Script-based installation
install_script_package() {
    local name="$1"
    local config="$2"
    
    local url=$(echo "$config" | yq eval '.url' -)
    local args=$(echo "$config" | yq eval '.args' -)
    
    local temp_script=$(mktemp)
    curl -fsSL "$url" > "$temp_script"
    chmod +x "$temp_script"
    
    if [[ -n "$args" && "$args" != "null" ]]; then
        "$temp_script" "$args"
    else
        "$temp_script"
    fi
    
    rm -f "$temp_script"
}

# Binary installation
install_binary_package() {
    local name="$1"
    local config="$2"
    
    local url=$(echo "$config" | yq eval '.url' -)
    local install_to=$(echo "$config" | yq eval '.install_to // "/usr/local/bin/"' -)
    local binary_name=$(echo "$config" | yq eval '.binary_name // ""' -)
    local extract_to=$(echo "$config" | yq eval '.extract_to // ""' -)
    
    local temp_dir=$(mktemp -d)
    local filename="${temp_dir}/download"
    
    info "Downloading from $url..."
    if ! curl -fsSL "$url" -o "$filename"; then
        error "Failed to download $url"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Handle archives vs single binaries
    if file "$filename" | grep -q "executable\|ELF"; then
        # Single binary
        local target_path="$install_to"
        if [[ "$install_to" == */ ]]; then
            target_path="${install_to}${binary_name:-$(basename "$url")}"
        fi
        info "Installing binary to $target_path..."
        sudo cp "$filename" "$target_path"
        sudo chmod +x "$target_path"
    else
        # Archive - extract and install
        local extract_dir="$temp_dir/extracted"
        
        if [[ -n "$extract_to" && "$extract_to" != "null" ]]; then
            # Extract to specified system location
            extract_dir="$extract_to"
            sudo mkdir -p "$extract_dir"
        else
            mkdir -p "$extract_dir"
        fi
        
        info "Extracting archive..."
        if file "$filename" | grep -q "gzip"; then
            if [[ -n "$extract_to" && "$extract_to" != "null" ]]; then
                sudo tar -xzf "$filename" -C "$extract_dir" --strip-components=1
            else
                tar -xzf "$filename" -C "$extract_dir"
            fi
        elif file "$filename" | grep -q "Zip"; then
            if [[ -n "$extract_to" && "$extract_to" != "null" ]]; then
                sudo unzip -q "$filename" -d "$extract_dir"
            else
                unzip -q "$filename" -d "$extract_dir"
            fi
        else
            error "Unsupported archive format"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # If extracting to system location, we're done
        if [[ -n "$extract_to" && "$extract_to" != "null" ]]; then
            info "Extracted to $extract_to"
        else
            # Copy specific binary or all executables
            if [[ -n "$binary_name" && "$binary_name" != "null" ]]; then
                local binary_file=$(find "$extract_dir" -name "$binary_name" -type f | head -1)
                if [[ -n "$binary_file" ]]; then
                    local target_path="$install_to"
                    [[ "$install_to" == */ ]] && target_path="${install_to}${binary_name}"
                    info "Installing $binary_name to $target_path..."
                    sudo cp "$binary_file" "$target_path"
                    sudo chmod +x "$target_path"
                else
                    error "Binary $binary_name not found in archive"
                    rm -rf "$temp_dir"
                    return 1
                fi
            else
                # Copy all executables
                info "Installing executables to $install_to..."
                find "$extract_dir" -type f -executable | while read -r exec_file; do
                    local exec_name=$(basename "$exec_file")
                    sudo cp "$exec_file" "${install_to}${exec_name}"
                    sudo chmod +x "${install_to}${exec_name}"
                done
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
}
