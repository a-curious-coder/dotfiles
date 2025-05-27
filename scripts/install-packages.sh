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

    # Only add repository if it's not empty and not null
    if [[ -n "$repository" && "$repository" != "null" ]]; then
        if [[ -n "$key" && "$key" != "null" ]]; then
            curl -fsSL "$key" | sudo apt-key add - 2>/dev/null || true
        fi
        echo "deb $repository stable main" | sudo tee /etc/apt/sources.list.d/${name}.list >/dev/null
        sudo apt update -qq
    fi

    # Install with silent flags to prevent GUI dialogs
    sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq "$package"
}

# Install package via snap
install_snap_package() {
    local package="$1"
    # Install with silent flags
    sudo snap install "$package" 2>/dev/null || true
}

# Install package via script with GUI prevention
install_script_package() {
    local url="$1"
    local args="${2:-}"

    # Set environment to prevent GUI apps from launching
    export DISPLAY=""
    export XDG_CURRENT_DESKTOP=""

    # Create a temporary script to handle the download properly
    local temp_script=$(mktemp)
    local temp_dir=$(mktemp -d)

    if [[ -n "$args" ]]; then
        curl -fsSL "$url" > "$temp_script" && chmod +x "$temp_script"
        cd "$temp_dir" && "$temp_script" "$args" 2>/dev/null || {
            warning "Script installation failed"
            rm -f "$temp_script"
            rm -rf "$temp_dir"
            return 1
        }
    else
        curl -fsSL "$url" > "$temp_script" && chmod +x "$temp_script"
        cd "$temp_dir" && "$temp_script" 2>/dev/null || {
            warning "Script installation failed"
            rm -f "$temp_script"
            rm -rf "$temp_dir"
            return 1
        }
    fi

    rm -f "$temp_script"
    rm -rf "$temp_dir"
}

# Install binary package
install_binary_package() {
    local url="$1"
    local extract_to="$2"
    local binary_name="${3:-}"
    local install_to="${4:-/usr/local/bin/}"
    local temp_dir=$(mktemp -d)

    info "Downloading $url..."
    local filename="${temp_dir}/downloaded_file"

    # Use wget with proper error handling and no interactive prompts
    if ! wget -q --no-check-certificate "$url" -O "$filename" 2>/dev/null; then
        error "Failed to download from $url"
        rm -rf "$temp_dir"
        return 1
    fi

    # Check if it's a compressed archive or a single binary
    if file "$filename" | grep -q "executable\|ELF"; then
        # It's a single binary file
        local binary_path="$install_to"
        if [[ "$install_to" == */ ]]; then
            # install_to is a directory, determine filename
            if [[ -n "$binary_name" ]]; then
                binary_path="${install_to}${binary_name}"
            else
                # Extract filename from URL
                binary_path="${install_to}$(basename "$url")"
            fi
        fi

        info "Installing binary to $binary_path..."
        sudo cp "$filename" "$binary_path"
        sudo chmod +x "$binary_path"
    else
        # It's an archive, extract it
        info "Extracting to $extract_to..."
        sudo mkdir -p "$extract_to"

        # Determine archive type and extract accordingly
        if file "$filename" | grep -q "gzip"; then
            # Use sudo and -o flag to automatically overwrite existing files
            sudo tar -xzf "$filename" -C "$extract_to" --overwrite 2>/dev/null || {
                error "Failed to extract tar.gz archive"
                rm -rf "$temp_dir"
                return 1
            }
        elif file "$filename" | grep -q "Zip"; then
            # Use -o to overwrite without prompting and redirect stdin from /dev/null
            sudo unzip -o "$filename" -d "$extract_to" < /dev/null 2>/dev/null || {
                error "Failed to extract zip archive"
                rm -rf "$temp_dir"
                return 1
            }
        else
            # Try tar first, then unzip as fallback
            sudo tar -xzf "$filename" -C "$extract_to" --overwrite < /dev/null 2>/dev/null || \
            sudo unzip -o "$filename" -d "$extract_to" < /dev/null 2>/dev/null || {
                error "Failed to extract archive (unknown format)"
                rm -rf "$temp_dir"
                return 1
            }
        fi

        if [[ -n "$binary_name" ]]; then
            # Find and copy the specific binary
            local binary_file=$(find "$extract_to" -name "$binary_name" -type f 2>/dev/null | head -n1)
            if [[ -n "$binary_file" ]]; then
                sudo cp "$binary_file" "$install_to"
                sudo chmod +x "${install_to}/${binary_name}"
            else
                warning "Binary $binary_name not found in extracted archive"
            fi
        else
            # Copy all executables (but be more selective)
            find "$extract_to" -type f -executable -name "*" 2>/dev/null | while read -r exec_file; do
                sudo cp "$exec_file" "$install_to" 2>/dev/null || true
                sudo chmod +x "${install_to}/$(basename "$exec_file")" 2>/dev/null || true
            done
        fi
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

    # Set environment for silent installation
    export DEBIAN_FRONTEND=noninteractive
    export DISPLAY=""
    export XDG_CURRENT_DESKTOP=""

    # Pre-configure packages to avoid interactive prompts
    info "Pre-configuring packages for silent installation..."

    # Wireshark configuration
    echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections

    # MySQL configuration for development (empty root password)
    echo "mysql-server mysql-server/root_password password " | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password " | sudo debconf-set-selections

    # Prevent services from auto-starting during installation
    cat > /tmp/policy-rc.d << 'EOF'
#!/bin/sh
exit 101
EOF
    sudo mv /tmp/policy-rc.d /usr/sbin/policy-rc.d
    sudo chmod +x /usr/sbin/policy-rc.d

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
                # Filter out null values
                [[ "$repo" == "null" ]] && repo=""
                [[ "$key" == "null" ]] && key=""
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
            "custom")
                # Handle special cases like AWS CLI
                case "$package" in
                    "aws-cli")
                        install_aws_cli
                        ;;
                    "burpsuite")
                        install_burpsuite
                        ;;
                    *)
                        error "Custom install method not implemented for $package"
                        ;;
                esac
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

# Install AWS CLI with special handling
install_aws_cli() {
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    info "Downloading AWS CLI..."
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    info "Extracting AWS CLI..."
    unzip -q awscliv2.zip

    info "Installing AWS CLI..."
    sudo ./aws/install

    # Cleanup
    rm -rf "$temp_dir"
}

# Install Burp Suite Community with improved handling
install_burpsuite() {
    local install_dir="/opt/burpsuite"
    local temp_dir=$(mktemp -d)

    info "Creating Burp Suite directory..."
    sudo mkdir -p "$install_dir"

    info "Downloading Burp Suite Community..."
    cd "$temp_dir"

    # Get the latest download URL from PortSwigger
    local download_url="https://portswigger.net/burp/releases/download?product=community&type=Linux"
    
    # Download with proper headers and follow redirects
    if ! curl -L -o "burpsuite_installer.sh" \
              -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
              --connect-timeout 30 \
              --max-time 300 \
              --retry 3 \
              --retry-delay 2 \
              --fail \
              "$download_url"; then
        warning "Failed to download Burp Suite installer, trying alternative method..."
        
        # Fallback: Install via snap if available
        if command -v snap &> /dev/null; then
            info "Installing Burp Suite via snap..."
            if sudo snap install burpsuite-community-edition; then
                success "Burp Suite Community installed via snap"
                return 0
            fi
        fi
        
        warning "Failed to install Burp Suite via snap as well. Please install manually from:"
        warning "https://portswigger.net/burp/communitydownload"
        rm -rf "$temp_dir"
        return 1
    fi

    # Make installer executable
    chmod +x burpsuite_installer.sh

    info "Installing Burp Suite (this may take a few minutes)..."
    
    # Create response file for silent installation
    cat > response.varfile << EOF
# Burp Suite Community Edition Installation Response File
sys.adminRights\$Boolean=true
sys.fileAssociation.extensions=
sys.fileAssociation.launchers=
sys.installationDir=$install_dir
sys.languageId=en
sys.programGroupDisabled\$Boolean=false
sys.symlinkDir=/usr/local/bin
EOF

    # Run installer in unattended mode
    if sudo ./burpsuite_installer.sh -q -varfile response.varfile; then
        # Verify installation
        if [[ -x "$install_dir/BurpSuiteCommunity" ]]; then
            # Create symlink if it doesn't exist
            if [[ ! -L "/usr/local/bin/burpsuite" ]]; then
                sudo ln -sf "$install_dir/BurpSuiteCommunity" "/usr/local/bin/burpsuite"
            fi
            success "Burp Suite Community installed successfully"
        else
            warning "Burp Suite installation completed but binary not found at expected location"
            # Look for the binary in common locations
            local burp_binary=$(find "$install_dir" -name "BurpSuiteCommunity" -o -name "burpsuite_community" 2>/dev/null | head -n1)
            if [[ -n "$burp_binary" ]]; then
                sudo ln -sf "$burp_binary" "/usr/local/bin/burpsuite"
                success "Found Burp Suite binary and created symlink"
            else
                warning "Please locate Burp Suite binary manually and create symlink if needed"
            fi
        fi
    else
        warning "Burp Suite installation failed. Saving installer for manual installation..."
        sudo cp burpsuite_installer.sh "$install_dir/"
        sudo chmod +x "$install_dir/burpsuite_installer.sh"
        warning "Run 'sudo $install_dir/burpsuite_installer.sh' to install manually with GUI"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

# Main execution
main() {
    info "Starting package installation..."
    process_packages
    install_oh_my_zsh

    # Cleanup: Remove policy file to allow services to start
    sudo rm -f /usr/sbin/policy-rc.d

    success "All packages installed successfully!"
}

main "$@"
