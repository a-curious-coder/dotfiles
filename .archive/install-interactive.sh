#!/usr/bin/env bash

# Interactive Package Installation Script
# ======================================
# Allows users to select exactly what they want to install

set -euo pipefai# Check if a tool is enabled in tool-selection.yaml
is_tool_enabled() {
    local tool="$1"
    local selection_file="${SCRIPT_DIR}/tool-selection.yaml"

    # If tool-selection.yaml doesn't exist, default to enabled
    if [[ ! -f "$selection_file" ]]; then
        return 0
    fi

    # Check if tool is explicitly disabled
    local enabled=$(yq eval ".tools.${tool}.enabled // true" "$selection_file" 2>/dev/null)
    [[ "$enabled" == "true" ]]
}

# Install selected tools
install_selected_tools() {
    local tools=("$@")
    local enabled_tools=()
    local disabled_tools=()

    # Filter tools based on tool-selection.yaml
    for tool in "${tools[@]}"; do
        if is_tool_enabled "$tool"; then
            enabled_tools+=("$tool")
        else
            disabled_tools+=("$tool")
        fi
    done

    if [[ ${#disabled_tools[@]} -gt 0 ]]; then
        warning "Skipping disabled tools: ${disabled_tools[*]}"
        info "Use 'scripts/manage-tools.sh' to enable them"
        echo ""
    fi

    if [[ ${#enabled_tools[@]} -eq 0 ]]; then
        warning "No enabled tools to install!"
        return 0
    fi

    info "Installing ${#enabled_tools[@]} enabled tools..."
    echo ""

    # Pre-configure packages to avoid prompts
    pre_configure_packages

    for tool in "${enabled_tools[@]}"; do
        install_single_tool "$tool"
    done

    success "Installation complete!"
}output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${DOTFILES_DIR}/config.yaml"

# Install yq for YAML parsing if not present
install_yq() {
    if ! command -v yq &> /dev/null; then
        info "Installing yq for YAML parsing..."
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
    fi
}

# Create package categories
declare -A CATEGORIES
CATEGORIES=(
    ["cybersecurity"]="wireshark nmap masscan burpsuite gobuster dirb ghidra gdb radare2 hashcat john binwalk steghide"
    ["development"]="git curl wget docker docker-compose nodejs golang rust python3-pip neovim vscode rbenv"
    ["databases"]="mysql-client postgresql-client redis-tools dbeaver"
    ["cloud"]="aws-cli terraform kubectl"
    ["api-tools"]="postman insomnia"
    ["productivity"]="bat ripgrep fd fzf tree jq htop tmux lsd stow unzip"
    ["shell"]="zsh"
    ["media"]="vlc firefox chromium gimp"
    ["cli-tools"]="yq lazydocker lazygit xclip build-essential cmake"
)

# Package descriptions for better UX
declare -A DESCRIPTIONS
DESCRIPTIONS=(
    ["cybersecurity"]="🔒 Security & CTF Tools - Network scanners, web security, reverse engineering, crypto tools"
    ["development"]="💻 Core Development - Programming languages, version control, containers, editors"
    ["databases"]="🗄️ Database Tools - MySQL, PostgreSQL, Redis clients and GUI tools"
    ["cloud"]="☁️ Cloud & Infrastructure - AWS CLI, Terraform, Kubernetes"
    ["api-tools"]="🌐 API Development - Postman, Insomnia for API testing"
    ["productivity"]="⚡ CLI Productivity - Modern CLI tools for enhanced workflow"
    ["shell"]="🐚 Shell Environment - Zsh shell configuration"
    ["media"]="🎬 Media & Browsers - Video player, web browsers, image editor"
    ["cli-tools"]="🔧 CLI Utilities - Additional command-line tools and utilities"
)

# Silent installation flags to prevent GUI apps from opening
export DEBIAN_FRONTEND=noninteractive
export DISPLAY=""
export XDG_CURRENT_DESKTOP=""

# Display banner
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════╗
    ║            🎯 Interactive Tool Installer             ║
    ║                                                      ║
    ║         Choose exactly what you want to install     ║
    ╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Show available categories
show_categories() {
    echo -e "${YELLOW}📦 Available Categories:${NC}"
    echo ""

    local i=1
    for category in "${!CATEGORIES[@]}"; do
        echo -e "${BLUE}[$i]${NC} ${DESCRIPTIONS[$category]}"
        i=$((i + 1))
    done

    echo ""
    echo -e "${BLUE}[a]${NC} 🚀 Install All (Full Setup)"
    echo -e "${BLUE}[c]${NC} 🎯 Custom Selection (Choose Individual Tools)"
    echo -e "${BLUE}[q]${NC} ❌ Quit"
    echo ""
}

# Show tools in a category
show_category_tools() {
    local category="$1"
    local tools="${CATEGORIES[$category]}"

    echo -e "${YELLOW}🔧 Tools in '$category' category:${NC}"
    echo ""

    for tool in $tools; do
        local name=$(yq eval ".packages.${tool}.name // \"${tool}\"" "$CONFIG_FILE" 2>/dev/null || echo "$tool")
        local installed=""
        local verify_cmd=$(yq eval ".packages.${tool}.verify_command // \"command -v ${tool}\"" "$CONFIG_FILE" 2>/dev/null || echo "command -v $tool")

        if eval "$verify_cmd" &> /dev/null; then
            installed=" ${GREEN}✓${NC}"
        else
            installed=" ${RED}✗${NC}"
        fi

        echo -e "  • ${name}${installed}"
    done
    echo ""
}

# Custom tool selection
custom_selection() {
    echo -e "${YELLOW}🎯 Custom Tool Selection${NC}"
    echo "Select individual tools to install:"
    echo ""

    # Get all available packages
    local packages=$(yq eval '.packages | keys | .[]' "$CONFIG_FILE")
    local selected_tools=()
    local i=1

    # Create numbered list
    declare -A tool_map
    while IFS= read -r package; do
        if [[ -n "$package" ]]; then
            local name=$(yq eval ".packages.${package}.name // \"${package}\"" "$CONFIG_FILE" 2>/dev/null || echo "$package")
            local verify_cmd=$(yq eval ".packages.${package}.verify_command // \"command -v ${package}\"" "$CONFIG_FILE" 2>/dev/null || echo "command -v $package")
            local installed=""

            if eval "$verify_cmd" &> /dev/null; then
                installed=" ${GREEN}✓${NC}"
            else
                installed=" ${RED}✗${NC}"
            fi

            echo -e "${BLUE}[$i]${NC} ${name}${installed}"
            tool_map[$i]="$package"
            i=$((i + 1))
        fi
    done <<< "$packages"

    echo ""
    echo "Enter tool numbers separated by spaces (e.g., 1 5 12 23), or 'all' for everything:"
    read -r selection

    if [[ "$selection" == "all" ]]; then
        while IFS= read -r package; do
            if [[ -n "$package" ]]; then
                selected_tools+=("$package")
            fi
        done <<< "$packages"
    else
        for num in $selection; do
            if [[ -n "${tool_map[$num]:-}" ]]; then
                selected_tools+=("${tool_map[$num]}")
            fi
        done
    fi

    if [[ ${#selected_tools[@]} -eq 0 ]]; then
        warning "No tools selected!"
        return 1
    fi

    install_selected_tools "${selected_tools[@]}"
}

# Install tools with proper handling for GUI apps
install_selected_tools() {
    local tools=("$@")

    info "Installing ${#tools[@]} selected tools..."
    echo ""

    # Pre-configure packages to avoid prompts
    pre_configure_packages

    for tool in "${tools[@]}"; do
        install_single_tool "$tool"
    done

    success "Installation complete!"
}

# Pre-configure packages to avoid interactive prompts
pre_configure_packages() {
    info "Pre-configuring packages to avoid prompts..."

    # Wireshark configuration - automatically select "Yes" for non-superusers
    echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections

    # MySQL configuration - set empty root password for development
    echo "mysql-server mysql-server/root_password password " | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password " | sudo debconf-set-selections

    # Prevent services from starting during installation
    cat > /tmp/policy-rc.d << 'EOF'
#!/bin/sh
exit 101
EOF
    sudo mv /tmp/policy-rc.d /usr/sbin/policy-rc.d
    sudo chmod +x /usr/sbin/policy-rc.d
}

# Install a single tool with proper error handling
install_single_tool() {
    local tool="$1"

    local name=$(yq eval ".packages.${tool}.name // \"${tool}\"" "$CONFIG_FILE" 2>/dev/null || echo "$tool")
    local install_method=$(yq eval ".packages.${tool}.install_method" "$CONFIG_FILE" 2>/dev/null || echo "")
    local verify_command=$(yq eval ".packages.${tool}.verify_command" "$CONFIG_FILE" 2>/dev/null || echo "command -v $tool")

    # Check if already installed
    if eval "$verify_command" &> /dev/null; then
        success "$name is already installed ✓"
        return 0
    fi

    info "Installing $name..."

    case "$install_method" in
        "apt")
            install_apt_tool "$tool"
            ;;
        "snap")
            install_snap_tool "$tool"
            ;;
        "script")
            install_script_tool "$tool"
            ;;
        "binary")
            install_binary_tool "$tool"
            ;;
        "appimage")
            install_appimage_tool "$tool"
            ;;
        "custom")
            install_custom_tool "$tool"
            ;;
        *)
            warning "Unknown install method for $tool: $install_method"
            return 1
            ;;
    esac

    # Run post-install commands
    run_post_install "$tool"

    # Verify installation
    if eval "$verify_command" &> /dev/null; then
        success "$name installed successfully ✓"
    else
        error "Failed to install $name ✗"
        return 1
    fi
}

# Install APT package with repository handling
install_apt_tool() {
    local tool="$1"
    local package=$(yq eval ".packages.${tool}.package" "$CONFIG_FILE")
    local repository=$(yq eval ".packages.${tool}.repository // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
    local key=$(yq eval ".packages.${tool}.key // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")

    # Filter out null values
    [[ "$repository" == "null" ]] && repository=""
    [[ "$key" == "null" ]] && key=""

    # Add repository if specified
    if [[ -n "$repository" && "$repository" != "null" ]]; then
        if [[ -n "$key" && "$key" != "null" ]]; then
            curl -fsSL "$key" | sudo apt-key add - 2>/dev/null || true
        fi
        echo "deb $repository stable main" | sudo tee /etc/apt/sources.list.d/${tool}.list >/dev/null
        sudo apt update -qq
    fi

    # Install with silent flags
    sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq "$package"
}

# Install snap package
install_snap_tool() {
    local tool="$1"
    local package=$(yq eval ".packages.${tool}.package" "$CONFIG_FILE")

    sudo snap install "$package" 2>/dev/null || true
}

# Install via script
install_script_tool() {
    local tool="$1"
    local url=$(yq eval ".packages.${tool}.url" "$CONFIG_FILE")
    local script_args=$(yq eval ".packages.${tool}.script_args // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")

    if [[ -n "$script_args" && "$script_args" != "null" ]]; then
        curl -fsSL "$url" | bash -s -- "$script_args"
    else
        curl -fsSL "$url" | bash
    fi
}

# Install binary package
install_binary_tool() {
    local tool="$1"
    local url=$(yq eval ".packages.${tool}.url" "$CONFIG_FILE")
    local extract_to=$(yq eval ".packages.${tool}.extract_to" "$CONFIG_FILE")
    local binary_name=$(yq eval ".packages.${tool}.binary_name // \"\"" "$CONFIG_FILE" 2>/dev/null || echo "")
    local install_to=$(yq eval ".packages.${tool}.install_to // \"/usr/local/bin/\"" "$CONFIG_FILE" 2>/dev/null || echo "/usr/local/bin/")

    local temp_dir=$(mktemp -d)
    local filename="${temp_dir}/downloaded_file"

    wget -q "$url" -O "$filename"

    # Check if it's a binary or archive
    if file "$filename" | grep -q "executable\|ELF"; then
        # Single binary
        local binary_path="$install_to"
        if [[ "$install_to" == */ ]]; then
            if [[ -n "$binary_name" && "$binary_name" != "null" ]]; then
                binary_path="${install_to}${binary_name}"
            else
                binary_path="${install_to}$(basename "$url")"
            fi
        fi

        sudo cp "$filename" "$binary_path"
        sudo chmod +x "$binary_path"
    else
        # Archive
        mkdir -p "$extract_to"

        if file "$filename" | grep -q "gzip"; then
            tar -xzf "$filename" -C "$extract_to"
        elif file "$filename" | grep -q "Zip"; then
            unzip -q "$filename" -d "$extract_to"
        fi

        if [[ -n "$binary_name" && "$binary_name" != "null" ]]; then
            sudo cp "${extract_to}/${binary_name}" "$install_to"
            sudo chmod +x "${install_to}/${binary_name}"
        fi
    fi

    rm -rf "$temp_dir"
}

# Install AppImage
install_appimage_tool() {
    local tool="$1"
    local url=$(yq eval ".packages.${tool}.url" "$CONFIG_FILE")
    local install_to=$(yq eval ".packages.${tool}.install_to" "$CONFIG_FILE")

    sudo wget -q "$url" -O "$install_to"
    sudo chmod +x "$install_to"
}

# Install custom tools
install_custom_tool() {
    local tool="$1"

    case "$tool" in
        "aws-cli")
            install_aws_cli_silent
            ;;
        "burpsuite")
            install_burpsuite_silent
            ;;
        "rbenv")
            install_rbenv_silent
            ;;
        *)
            error "Custom install not implemented for $tool"
            return 1
            ;;
    esac
}

# Silent AWS CLI installation
install_aws_cli_silent() {
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update

    rm -rf "$temp_dir"
}

# Silent Burp Suite installation
install_burpsuite_silent() {
    local install_dir="/opt/burpsuite"
    local temp_dir=$(mktemp -d)

    info "Creating Burp Suite directory..."
    sudo mkdir -p "$install_dir"

    cd "$temp_dir"

    # Download with proper user agent and silent flags
    if wget --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
            --content-disposition \
            --trust-server-names \
            --quiet \
            "https://portswigger.net/burp/releases/download?product=community&type=Linux" \
            2>/dev/null; then

        # Find the downloaded jar file
        local jar_file=$(find . -name "*.jar" | head -n1)
        if [[ -n "$jar_file" ]]; then
            sudo cp "$jar_file" "$install_dir/"

            # Create a wrapper script
            sudo tee "$install_dir/burpsuite" > /dev/null << EOF
#!/bin/bash
java -jar "$install_dir/$(basename "$jar_file")" "\$@"
EOF
            sudo chmod +x "$install_dir/burpsuite"

            # Create symlink for system-wide access
            sudo ln -sf "$install_dir/burpsuite" "/usr/local/bin/burpsuite" 2>/dev/null || true
        fi
    fi

    rm -rf "$temp_dir"
}

# Silent rbenv installation
install_rbenv_silent() {
    info "Installing rbenv (Ruby version manager)..."

    # Clone rbenv if not already installed
    if [[ ! -d "${HOME}/.rbenv" ]]; then
        git clone https://github.com/rbenv/rbenv.git "${HOME}/.rbenv"

        # Clone ruby-build plugin
        mkdir -p "${HOME}/.rbenv/plugins"
        git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"

        # Make rbenv binary executable
        chmod +x "${HOME}/.rbenv/bin/rbenv"

        # Add to PATH for current session
        export PATH="${HOME}/.rbenv/bin:$PATH"
        eval "$(${HOME}/.rbenv/bin/rbenv init -)"

        success "rbenv installed successfully"
        info "Run 'rbenv install 3.1.0' to install Ruby 3.1.0"
        info "Run 'rbenv global 3.1.0' to set it as default"
    else
        success "rbenv already installed"
    fi
}

# Run post-install commands
run_post_install() {
    local tool="$1"
    local post_install_commands=$(yq eval ".packages.${tool}.post_install[]?" "$CONFIG_FILE" 2>/dev/null || echo "")

    if [[ -n "$post_install_commands" && "$post_install_commands" != "null" ]]; then
        while IFS= read -r cmd; do
            if [[ -n "$cmd" && "$cmd" != "null" ]]; then
                eval "$cmd" 2>/dev/null || true
            fi
        done <<< "$post_install_commands"
    fi
}

# Cleanup function
cleanup() {
    # Remove policy file to allow services to start again
    sudo rm -f /usr/sbin/policy-rc.d
}

# Main interactive menu
main() {
    install_yq

    # Set trap for cleanup
    trap cleanup EXIT

    show_banner

    while true; do
        show_categories
        echo -n "Select option: "
        read -r choice

        case "$choice" in
            [1-9])
                local categories_array=($(printf '%s\n' "${!CATEGORIES[@]}" | sort))
                local selected_category="${categories_array[$((choice-1))]}"

                if [[ -n "$selected_category" ]]; then
                    show_category_tools "$selected_category"
                    echo -n "Install all tools in this category? (y/N): "
                    read -r confirm

                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        local tools_array=(${CATEGORIES[$selected_category]})
                        install_selected_tools "${tools_array[@]}"

                        echo ""
                        echo -n "Continue with another category? (y/N): "
                        read -r continue_choice
                        [[ ! "$continue_choice" =~ ^[Yy]$ ]] && break
                    fi
                fi
                ;;
            "a"|"A")
                echo -n "Install ALL tools? This will take a while! (y/N): "
                read -r confirm

                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    local all_tools=()
                    for category_tools in "${CATEGORIES[@]}"; do
                        local tools_array=($category_tools)
                        all_tools+=("${tools_array[@]}")
                    done
                    install_selected_tools "${all_tools[@]}"
                    break
                fi
                ;;
            "c"|"C")
                custom_selection

                echo ""
                echo -n "Continue with another selection? (y/N): "
                read -r continue_choice
                [[ ! "$continue_choice" =~ ^[Yy]$ ]] && break
                ;;
            "q"|"Q")
                info "Goodbye! 👋"
                exit 0
                ;;
            *)
                warning "Invalid choice. Please try again."
                ;;
        esac
    done

    success "Installation session complete! 🎉"
    info "Run 'show-tools' to see all installed tools"
}

main "$@"
