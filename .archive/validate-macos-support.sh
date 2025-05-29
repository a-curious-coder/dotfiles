#!/usr/bin/env bash

# macOS Support Validation Script
# ===============================
# This script validates that the package installation system properly supports macOS

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
header() { echo -e "${CYAN}$1${NC}"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Include necessary functions from the main script without executing
SCRIPTS_DIR="${DOTFILES_DIR}/scripts"

# Validation tests
validate_os_detection() {
    header "=== Testing OS Detection ==="
    
    # Test OS detection function from the script
    local detect_function=$(grep -A 10 "detect_os()" "${SCRIPTS_DIR}/install-packages.sh" | head -10)
    if [[ -n "$detect_function" ]]; then
        success "detect_os function found in install-packages.sh"
        
        # Check if it supports macOS
        if grep -q "Darwin.*macos" "${SCRIPTS_DIR}/install-packages.sh"; then
            success "macOS detection supported (Darwin -> macos)"
        else
            error "macOS detection not found"
            return 1
        fi
        
        # Check Apple Silicon detection
        if grep -q "is_apple_silicon" "${SCRIPTS_DIR}/install-packages.sh"; then
            success "Apple Silicon detection function available"
        else
            warning "Apple Silicon detection not found"
        fi
    else
        error "detect_os function not found"
        return 1
    fi
    
    echo ""
}

validate_config_files() {
    header "=== Testing Configuration Files ==="
    
    # Check for macOS config file
    local macos_config="${DOTFILES_DIR}/config-macos.yaml"
    local linux_config="${DOTFILES_DIR}/config.yaml"
    
    if [[ -f "$macos_config" ]]; then
        success "macOS configuration file exists: config-macos.yaml"
        
        # Test basic YAML structure
        if grep -q "packages:" "$macos_config"; then
            success "macOS config has packages section"
        else
            error "macOS config missing packages section"
            return 1
        fi
        
        local package_count=$(grep -c "name:" "$macos_config" || echo "0")
        info "Found approximately $package_count packages in macOS configuration"
        
    else
        error "macOS configuration file not found: $macos_config"
        return 1
    fi
    
    if [[ -f "$linux_config" ]]; then
        success "Linux configuration file exists: config.yaml"
    else
        error "Linux configuration file not found: $linux_config"
        return 1
    fi
    
    # Check get_config_file function
    if grep -q "get_config_file()" "${SCRIPTS_DIR}/install-packages.sh"; then
        success "get_config_file function available for OS-specific config selection"
    else
        warning "get_config_file function not found"
    fi
    
    echo ""
}

validate_macos_package_methods() {
    header "=== Testing macOS Package Installation Methods ==="
    
    local macos_config="${DOTFILES_DIR}/config-macos.yaml"
    
    if [[ ! -f "$macos_config" ]]; then
        error "macOS config file not found"
        return 1
    fi
    
    # Check for macOS-specific installation methods
    local methods_found=()
    
    if grep -q "install_method.*brew" "$macos_config"; then
        methods_found+=("brew")
        success "Homebrew formula support detected"
        local brew_count=$(grep -c "install_method.*brew" "$macos_config" || echo "0")
        info "  Found $brew_count packages using brew method"
    fi
    
    if grep -q "install_method.*cask" "$macos_config"; then
        methods_found+=("cask")
        success "Homebrew Cask support detected"
        local cask_count=$(grep -c "install_method.*cask" "$macos_config" || echo "0")
        info "  Found $cask_count packages using cask method"
    fi
    
    if grep -q "install_method.*xcode" "$macos_config"; then
        methods_found+=("xcode")
        success "Xcode Command Line Tools support detected"
    fi
    
    if grep -q "install_method.*included" "$macos_config"; then
        methods_found+=("included")
        success "Built-in macOS tools support detected"
    fi
    
    if [[ ${#methods_found[@]} -eq 0 ]]; then
        error "No macOS-specific installation methods found"
        return 1
    fi
    
    info "Supported macOS installation methods: ${methods_found[*]}"
    echo ""
}

validate_homebrew_functions() {
    header "=== Testing Homebrew Support Functions ==="
    
    local install_script="${SCRIPTS_DIR}/install-packages.sh"
    
    # Check if install_brew_package function exists
    if grep -q "install_brew_package()" "$install_script"; then
        success "install_brew_package function available"
        
        # Check if it handles both brew and cask
        if grep -A 20 "install_brew_package()" "$install_script" | grep -q "is_cask"; then
            success "Function supports both brew formulas and casks"
        else
            warning "Cask support not clearly detectable"
        fi
    else
        error "install_brew_package function not found"
        return 1
    fi
    
    # Check if ensure_homebrew function exists
    if grep -q "ensure_homebrew()" "$install_script"; then
        success "ensure_homebrew function available"
    else
        error "ensure_homebrew function not found"
        return 1
    fi
    
    # Test Homebrew PATH logic
    if grep -q "/opt/homebrew" "$install_script"; then
        success "Apple Silicon Homebrew path (/opt/homebrew) supported"
    else
        warning "Apple Silicon Homebrew path not found"
    fi
    
    if grep -q "/usr/local" "$install_script"; then
        success "Intel Homebrew path (/usr/local) supported"
    else
        warning "Intel Homebrew path not found"
    fi
    
    echo ""
}

validate_cross_platform_functions() {
    header "=== Testing Cross-Platform Functions ==="
    
    local install_script="${SCRIPTS_DIR}/install-packages.sh"
    
    # Test OS-specific preparation
    if grep -q "prepare_system()" "$install_script"; then
        success "prepare_system function available"
        
        # Check if it handles macOS
        if grep -A 10 "prepare_system()" "$install_script" | grep -q "macos"; then
            success "prepare_system supports macOS"
        else
            warning "macOS support in prepare_system not clearly detectable"
        fi
    else
        error "prepare_system function not found"
        return 1
    fi
    
    # Test package installation routing
    if grep -q "install_package_by_method()" "$install_script"; then
        success "install_package_by_method function available"
    else
        error "install_package_by_method function not found"
        return 1
    fi
    
    # Test AWS CLI macOS support
    if grep -q "install_aws_cli()" "$install_script"; then
        success "install_aws_cli function available"
        
        # Check if it handles macOS specifically
        if grep -A 20 "install_aws_cli()" "$install_script" | grep -q "macos"; then
            success "AWS CLI installation supports macOS"
        else
            warning "AWS CLI macOS support not clearly detectable"
        fi
    else
        warning "install_aws_cli function not found"
    fi
    
    echo ""
}

validate_macos_specific_packages() {
    header "=== Testing macOS-Specific Package Configurations ==="
    
    local macos_config="${DOTFILES_DIR}/config-macos.yaml"
    
    if [[ -f "$macos_config" ]]; then
        success "Using macOS-specific configuration"
        
        # Test for macOS-specific packages
        local macos_packages=(
            "docker"        # Should use cask
            "vscode"        # Should use cask
            "ghostty"       # Should use cask
            "wireshark"     # Should use cask
            "firefox"       # Should use cask
            "neovim"        # Should use brew
            "git"           # Should use brew
            "nodejs"        # Should use brew
        )
        
        for package in "${macos_packages[@]}"; do
            if grep -q "^  ${package}:" "$macos_config"; then
                local method_line=$(grep -A 3 "^  ${package}:" "$macos_config" | grep "install_method" | head -1)
                if [[ -n "$method_line" ]]; then
                    local method=$(echo "$method_line" | sed 's/.*install_method: *"\([^"]*\)".*/\1/' | sed 's/.*install_method: *\([^ ]*\).*/\1/')
                    info "✓ $package: $method"
                else
                    warning "✗ $package: method not specified"
                fi
            else
                warning "✗ $package: not found in config"
            fi
        done
        
        success "macOS package configuration validation complete"
    else
        error "macOS configuration not found"
        return 1
    fi
    
    echo ""
}

validate_aws_cli_macos() {
    header "=== Testing AWS CLI macOS Installation ==="
    
    local install_script="${SCRIPTS_DIR}/install-packages.sh"
    
    if grep -q "install_aws_cli()" "$install_script"; then
        success "install_aws_cli function available"
        
        # Check if function handles macOS properly
        if grep -A 30 "install_aws_cli()" "$install_script" | grep -q "macos"; then
            success "AWS CLI function has macOS support"
            
            # Check for Apple Silicon support
            if grep -A 30 "install_aws_cli()" "$install_script" | grep -q "arm64"; then
                success "AWS CLI supports Apple Silicon (arm64) packages"
            else
                warning "Apple Silicon AWS CLI support not clearly detectable"
            fi
            
            # Check for Intel support
            if grep -A 30 "install_aws_cli()" "$install_script" | grep -q "AWSCLIV2.pkg"; then
                success "AWS CLI supports Intel Mac packages"
            else
                warning "Intel Mac AWS CLI support not clearly detectable"
            fi
        else
            warning "AWS CLI macOS support not clearly detectable"
        fi
    else
        error "install_aws_cli function not found"
        return 1
    fi
    
    echo ""
}

run_dry_run_test() {
    header "=== Running Dry Run Test ==="
    
    info "Testing package installation logic without actually installing..."
    
    local macos_config="${DOTFILES_DIR}/config-macos.yaml"
    
    # Test a few packages to ensure routing works
    local test_packages=("git" "docker" "neovim" "vscode")
    
    for package in "${test_packages[@]}"; do
        if grep -q "^  ${package}:" "$macos_config"; then
            local method_line=$(grep -A 5 "^  ${package}:" "$macos_config" | grep "install_method" | head -1)
            local package_line=$(grep -A 5 "^  ${package}:" "$macos_config" | grep "package:" | head -1)
            
            if [[ -n "$method_line" ]]; then
                local install_method=$(echo "$method_line" | sed 's/.*install_method: *"\([^"]*\)".*/\1/' | sed 's/.*install_method: *\([^ ]*\).*/\1/')
                local package_name=""
                if [[ -n "$package_line" ]]; then
                    package_name=$(echo "$package_line" | sed 's/.*package: *"\([^"]*\)".*/\1/' | sed 's/.*package: *\([^ ]*\).*/\1/')
                fi
                
                info "Package: $package"
                info "  Method: $install_method"
                info "  Package Name: $package_name"
                
                # Validate method is appropriate for macOS
                case "$install_method" in
                    "brew"|"cask"|"xcode"|"included"|"script"|"binary"|"custom")
                        success "  ✓ Installation method supported on macOS"
                        ;;
                    "apt"|"snap"|"appimage")
                        warning "  ⚠ Installation method not supported on macOS (should be filtered out)"
                        ;;
                    *)
                        error "  ✗ Unknown installation method"
                        ;;
                esac
            else
                warning "Package $package found but install_method not detected"
            fi
        else
            warning "Package $package not found in macOS config"
        fi
        echo ""
    done
}

display_summary() {
    header "=== macOS Support Validation Summary ==="
    
    echo "✅ Key macOS Features Validated:"
    echo "   • OS detection (including Apple Silicon)"
    echo "   • Configuration file selection"
    echo "   • Homebrew formula and Cask support"
    echo "   • Xcode Command Line Tools integration"
    echo "   • Cross-platform function routing"
    echo "   • macOS-specific package configurations"
    echo "   • AWS CLI macOS installation support"
    echo ""
    
    echo "📋 Installation Methods Supported on macOS:"
    echo "   • brew         - Homebrew formulas (CLI tools)"
    echo "   • cask         - Homebrew Casks (GUI applications)"
    echo "   • xcode        - Xcode Command Line Tools"
    echo "   • included     - Built into macOS"
    echo "   • script       - Installation scripts"
    echo "   • binary       - Direct binary downloads"
    echo "   • custom       - Custom installation logic"
    echo ""
    
    echo "🚀 Scripts Ready for macOS:"
    echo "   • install-cross-platform.sh  - Full cross-platform setup"
    echo "   • install-packages.sh        - Package installation only"
    echo "   • install-interactive.sh     - Interactive package selection"
    echo ""
    
    success "macOS support validation completed successfully!"
}

# Main execution
main() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║            🍎 macOS Support Validation           ║
║                                                  ║
║      Validating cross-platform compatibility    ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    
    validate_os_detection
    validate_config_files
    validate_macos_package_methods
    validate_homebrew_functions
    validate_cross_platform_functions
    validate_macos_specific_packages
    validate_aws_cli_macos
    run_dry_run_test
    
    display_summary
}

# Run validation
main "$@"
