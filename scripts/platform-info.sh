#!/usr/bin/env bash

# Platform Detection and Information Utility
# ===========================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Get detailed OS information
get_os_details() {
    local os="$(detect_os)"
    
    case "$os" in
        linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                echo "$PRETTY_NAME"
            else
                echo "Linux (unknown distribution)"
            fi
            ;;
        macos)
            local version
            version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            local build
            build=$(sw_vers -buildVersion 2>/dev/null || echo "unknown")
            echo "macOS $version (Build: $build)"
            ;;
        *)
            echo "Unknown OS"
            ;;
    esac
}

# Check architecture
get_architecture() {
    uname -m
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]] && [[ "$(detect_os)" == "macos" ]]
}

# Check package managers
check_package_managers() {
    local os="$(detect_os)"
    
    echo -e "${BLUE}Package Managers:${NC}"
    
    case "$os" in
        linux)
            command -v apt >/dev/null && echo "  ✅ APT ($(apt --version | head -1))"
            command -v snap >/dev/null && echo "  ✅ Snap ($(snap version | grep snap | awk '{print $2}'))"
            command -v flatpak >/dev/null && echo "  ✅ Flatpak ($(flatpak --version))"
            command -v brew >/dev/null && echo "  ✅ Homebrew ($(brew --version | head -1))"
            ;;
        macos)
            command -v brew >/dev/null && echo "  ✅ Homebrew ($(brew --version | head -1))" || echo "  ❌ Homebrew (not installed)"
            command -v port >/dev/null && echo "  ✅ MacPorts ($(port version | head -1))"
            ;;
    esac
    echo ""
}

# Check development tools
check_dev_tools() {
    echo -e "${BLUE}Development Tools:${NC}"
    
    # Common tools
    command -v git >/dev/null && echo "  ✅ Git ($(git --version | cut -d' ' -f3))" || echo "  ❌ Git"
    command -v curl >/dev/null && echo "  ✅ curl ($(curl --version | head -1 | cut -d' ' -f2))" || echo "  ❌ curl"
    command -v wget >/dev/null && echo "  ✅ wget ($(wget --version | head -1 | cut -d' ' -f3))" || echo "  ❌ wget"
    command -v docker >/dev/null && echo "  ✅ Docker ($(docker --version | cut -d' ' -f3 | tr -d ','))" || echo "  ❌ Docker"
    command -v code >/dev/null && echo "  ✅ VS Code ($(code --version | head -1))" || echo "  ❌ VS Code"
    command -v nvim >/dev/null && echo "  ✅ Neovim ($(nvim --version | head -1 | cut -d' ' -f2))" || echo "  ❌ Neovim"
    
    # OS-specific
    local os="$(detect_os)"
    case "$os" in
        linux)
            command -v sudo >/dev/null && echo "  ✅ sudo" || echo "  ❌ sudo"
            ;;
        macos)
            xcode-select -p >/dev/null 2>&1 && echo "  ✅ Xcode Command Line Tools" || echo "  ❌ Xcode Command Line Tools"
            ;;
    esac
    echo ""
}

# Check shell environment
check_shell() {
    echo -e "${BLUE}Shell Environment:${NC}"
    echo "  Current Shell: $SHELL"
    command -v zsh >/dev/null && echo "  ✅ Zsh ($(zsh --version | cut -d' ' -f2))" || echo "  ❌ Zsh"
    [[ -d "${HOME}/.oh-my-zsh" ]] && echo "  ✅ Oh My Zsh" || echo "  ❌ Oh My Zsh"
    command -v tmux >/dev/null && echo "  ✅ tmux ($(tmux -V | cut -d' ' -f2))" || echo "  ❌ tmux"
    echo ""
}

# Get installation recommendations
get_recommendations() {
    local os="$(detect_os)"
    
    echo -e "${YELLOW}Installation Recommendations:${NC}"
    
    case "$os" in
        linux)
            echo "  📦 Use: ./install.sh (Linux-optimized)"
            echo "  🔄 Alternative: ./install-cross-platform.sh"
            if ! command -v sudo >/dev/null; then
                echo "  ⚠️  Install sudo first: apt install sudo"
            fi
            ;;
        macos)
            echo "  📦 Use: ./install-cross-platform.sh (macOS-optimized)"
            if ! command -v brew >/dev/null; then
                echo "  🍺 Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
            if ! xcode-select -p >/dev/null 2>&1; then
                echo "  🔧 Install Xcode tools: xcode-select --install"
            fi
            if is_apple_silicon; then
                echo "  🚀 Apple Silicon detected - using optimized packages"
            fi
            ;;
        *)
            echo "  ❌ Unsupported platform"
            ;;
    esac
    echo ""
}

# Show platform summary
show_platform_info() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║              Platform Information                ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${GREEN}System Details:${NC}"
    echo "  OS: $(get_os_details)"
    echo "  Architecture: $(get_architecture)"
    echo "  Hostname: $(hostname)"
    echo ""
    
    check_package_managers
    check_dev_tools  
    check_shell
    get_recommendations
}

# Main function
main() {
    case "${1:-}" in
        --help|-h)
            echo "Platform Detection Utility"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help, -h        Show this help message"
            echo "  --os              Show OS type only"
            echo "  --arch            Show architecture only"
            echo "  --full            Show full platform information (default)"
            echo ""
            ;;
        --os)
            detect_os
            ;;
        --arch)
            get_architecture
            ;;
        --full|"")
            show_platform_info
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
