#!/usr/bin/env bash

# Post-installation Tasks
# =======================

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

# ===========================
# CROSS-PLATFORM DETECTION
# ===========================

# Detect the operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "windows";;
        MINGW*)     echo "windows";;
        *)          echo "unknown";;
    esac
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]] && [[ "$(detect_os)" == "macos" ]]
}

# ===========================
# DEVELOPMENT ENVIRONMENT SETUP
# ===========================

# Setup NVM for Node.js version management
setup_nvm() {
    info "Setting up NVM (Node Version Manager)..."
    local os="$(detect_os)"

    if [[ ! -d "${HOME}/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Install latest LTS Node.js
        nvm install --lts
        nvm use --lts
        success "NVM and Node.js LTS installed"
    else
        success "NVM already installed"
    fi
}

# Setup Rust environment
setup_rust() {
    info "Setting up Rust environment..."
    local os="$(detect_os)"

    if ! command -v rustc &> /dev/null; then
        info "Installing Rust..."
        case "$os" in
            linux|macos)
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                ;;
            *)
                warning "Manual Rust installation required for $os"
                return 0
                ;;
        esac
    fi

    # Source Rust environment if it exists
    if [[ -f "${HOME}/.cargo/env" ]]; then
        source "${HOME}/.cargo/env"
        success "Rust environment configured"
    fi
}

# Setup Homebrew environment (macOS only)
setup_homebrew_env() {
    local os="$(detect_os)"
    
    if [[ "$os" == "macos" ]]; then
        info "Configuring Homebrew environment..."
        
        # Add Homebrew to PATH based on architecture
        if is_apple_silicon; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        success "Homebrew environment configured"
    fi
}

# Configure Git if not already configured
setup_git_config() {
    info "Checking Git configuration..."

    if [[ -z "$(git config --global user.name 2>/dev/null || true)" ]]; then
        warning "Git user.name not configured"
        info "You can configure it later with: git config --global user.name 'Your Name'"
    fi

    if [[ -z "$(git config --global user.email 2>/dev/null || true)" ]]; then
        warning "Git user.email not configured"
        info "You can configure it later with: git config --global user.email 'your.email@example.com'"
    fi
}

# Install Python packages for security and CTF
install_python_packages() {
    info "Installing Python packages for development and security..."
    local os="$(detect_os)"

    # Ensure pip3 is available
    case "$os" in
        linux)
            if ! command -v pip3 &> /dev/null; then
                warning "pip3 not found, installing python3-pip..."
                sudo apt install -y python3-pip
            fi
            ;;
        macos)
            if ! command -v pip3 &> /dev/null; then
                warning "pip3 not found, installing python via Homebrew..."
                brew install python
            fi
            ;;
    esac

    if command -v pip3 &> /dev/null; then
        local packages=(
            "pwntools"
            "requests"
            "beautifulsoup4"
            "scapy"
            "cryptography"
            "pycrypto"
            "pillow"
            "numpy"
            "sqlparse"
            "paramiko"
            "impacket"
            "volatility3"
            "flask"
            "django"
            "fastapi"
            "pytest"
            "black"
            "pylint"
        )

        for package in "${packages[@]}"; do
            info "Installing Python package: $package"
            pip3 install --user "$package" 2>/dev/null || warning "Failed to install $package"
        done

        success "Python packages installed"
    else
        warning "pip3 not found, skipping Python package installation"
    fi
}

# Install VS Code extensions
install_vscode_extensions() {
    info "Installing VS Code extensions..."
    local os="$(detect_os)"

    # Check for VS Code installation with platform-specific commands
    local vscode_cmd=""
    case "$os" in
        linux)
            if command -v code &> /dev/null; then
                vscode_cmd="code"
            elif command -v code-insiders &> /dev/null; then
                vscode_cmd="code-insiders"
            fi
            ;;
        macos)
            if command -v code &> /dev/null; then
                vscode_cmd="code"
            elif [[ -d "/Applications/Visual Studio Code.app" ]]; then
                vscode_cmd="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
            elif [[ -d "/Applications/Visual Studio Code - Insiders.app" ]]; then
                vscode_cmd="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
            fi
            ;;
    esac

    if [[ -n "$vscode_cmd" ]]; then
        # Essential extensions
        local extensions=(
            "ms-vscode.vscode-json"
            "ms-vscode.cpptools"
            "golang.Go"
            "rust-lang.rust-analyzer"
            "ms-python.python"
            "bradlc.vscode-tailwindcss"
            "esbenp.prettier-vscode"
            "ms-vscode.vscode-typescript-next"
            "ms-vscode-remote.remote-ssh"
            "vscodevim.vim"
            "github.copilot"
            "github.copilot-chat"
            "ms-vscode.theme-monokai-dimmed"
            "ms-vscode.hexeditor"
            "ms-toolsai.jupyter"
            "redhat.vscode-yaml"
            "hashicorp.terraform"
            "ms-kubernetes-tools.vscode-kubernetes-tools"
            "ms-vscode.powershell"
        )

        for extension in "${extensions[@]}"; do
            info "Installing VS Code extension: $extension"
            code --install-extension "$extension" --force 2>/dev/null || warning "Failed to install $extension"
        done

        success "VS Code extensions installed"
    else
        warning "VS Code not found, skipping extension installation"
    fi
}

# Set up development environment variables
setup_environment() {
    info "Setting up development environment..."

    # Reload shell environment
    if [[ -f "${HOME}/.zshrc" ]]; then
        source "${HOME}/.zshrc" 2>/dev/null || true
    fi

    success "Environment configured"
}

# Create useful aliases and scripts
setup_aliases() {
    info "Setting up useful development aliases..."

    # These will be in the .zshrc file, but we can verify they're working
    if command -v lazydocker &> /dev/null && command -v lazygit &> /dev/null; then
        success "Lazy tools available"
    fi
}

# Show manual installation recommendations
show_manual_recommendations() {
    info "Showing additional software recommendations..."

    echo ""
    warning "=== MANUAL INSTALLATIONS RECOMMENDED ==="
    echo ""
    info "🔒 VPN Software:"
    info "  • Private Internet Access (PIA) - https://www.privateinternetaccess.com/download"
    info "  • OpenVPN: sudo apt install openvpn"
    info "  • WireGuard: sudo apt install wireguard"
    echo ""
    info "🛡️ Additional Security Tools:"
    info "  • Metasploit Framework: curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall"
    info "  • OWASP ZAP: https://www.zaproxy.org/download/"
    info "  • Bloodhound: https://github.com/BloodHoundAD/BloodHound"
    echo ""
    info "💻 Development IDEs:"
    info "  • JetBrains IDEs: https://www.jetbrains.com/"
    info "  • Android Studio: https://developer.android.com/studio"
    echo ""
    info "🖥️ Virtualization:"
    info "  • VirtualBox: sudo apt install virtualbox"
    info "  • VMware Workstation: Download from VMware website"
    info "  • QEMU/KVM: sudo apt install qemu-kvm virt-manager"
    echo ""
}

# Main execution
main() {
    info "Running post-installation tasks..."

    setup_nvm
    setup_rust
    setup_homebrew_env
    setup_git_config
    install_vscode_extensions
    install_python_packages
    setup_environment
    setup_aliases
    show_manual_recommendations

    success "Post-installation tasks completed!"
    success ""
    success "🎉 Your development environment is ready!"
    success ""
    info "Next steps:"
    info "1. Restart your terminal or run 'source ~/.zshrc'"
    info "2. Configure Git credentials: 'scripts/setup-git-user.sh'"
    info "3. Run './scripts/show-tools.sh' to see what's installed"
    info "4. Check 'CTF-GUIDE.md' for security tools usage"
    info "5. Use 'ctf-workspace <name>' to start CTF challenges"
    success ""
}

main "$@"
