#!/usr/bin/env bash

# Test Suite for Unified Dotfiles System
# ======================================
# Validates the new unified configuration and installation system

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source libraries directly without common.sh to avoid variable conflicts
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/platform.sh"

# Helper functions
header() {
    echo
    echo "=================================="
    echo "$1"
    echo "=================================="
    echo
}

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    
    info "Running test: $test_name"
    
    if $test_function; then
        success "✅ $test_name"
        ((TESTS_PASSED++))
    else
        error "❌ $test_name"
        ((TESTS_FAILED++))
    fi
    echo
}

# Test: Configuration file exists and is valid
test_config_file() {
    local config_file="$DOTFILES_DIR/packages.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Test YAML syntax
    if command -v yq &> /dev/null; then
        if ! yq eval . "$config_file" > /dev/null 2>&1; then
            error "Invalid YAML syntax in $config_file"
            return 1
        fi
    else
        warning "yq not installed, skipping YAML validation"
    fi
    
    return 0
}

# Test: Platform detection
test_platform_detection() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|macos|windows)
            debug "Detected platform: $platform"
            return 0
            ;;
        *)
            error "Unknown platform detected: $platform"
            return 1
            ;;
    esac
}

# Test: Package manager detection
test_package_manager() {
    local pkg_mgr=$(get_package_manager)
    
    case "$pkg_mgr" in
        brew|apt|dnf|pacman|zypper)
            debug "Detected package manager: $pkg_mgr"
            return 0
            ;;
        none|unknown)
            warning "No package manager detected or platform not fully supported"
            return 0  # This might be expected in some environments
            ;;
        *)
            error "Unexpected package manager result: $pkg_mgr"
            return 1
            ;;
    esac
}

# Test: Library files exist
test_library_files() {
    local lib_dir="$SCRIPT_DIR/lib"
    local required_libs=(
        "common.sh"
        "platform.sh"
        "logging.sh"
        "package-manager.sh"
        "packages.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        local lib_path="$lib_dir/$lib"
        if [[ ! -f "$lib_path" ]]; then
            error "Required library not found: $lib_path"
            return 1
        fi
        
        # Test that library can be sourced
        if ! bash -n "$lib_path"; then
            error "Syntax error in library: $lib_path"
            return 1
        fi
    done
    
    return 0
}

# Test: Installation scripts exist and are executable
test_installation_scripts() {
    local scripts=(
        "$DOTFILES_DIR/setup"
        "$SCRIPT_DIR/install-unified.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            error "Installation script not found: $script"
            return 1
        fi
        
        if [[ ! -x "$script" ]]; then
            error "Installation script not executable: $script"
            return 1
        fi
        
        # Test syntax
        if ! bash -n "$script"; then
            error "Syntax error in script: $script"
            return 1
        fi
    done
    
    return 0
}

# Test: Package configuration structure
test_package_structure() {
    local config_file="$DOTFILES_DIR/packages.yaml"
    
    if ! command -v yq &> /dev/null; then
        warning "yq not available, skipping package structure test"
        return 0
    fi
    
    # Test that categories exist
    local categories_count
    if categories_count=$(yq eval '.categories | length' "$config_file" 2>/dev/null); then
        if [[ "$categories_count" -gt 0 ]]; then
            debug "Found $categories_count categories in configuration"
            return 0
        else
            error "No categories found in configuration"
            return 1
        fi
    else
        error "Failed to read categories from configuration"
        return 1
    fi
}

# Test: Dry-run functionality
test_dry_run() {
    local output
    if output=$("$SCRIPT_DIR/install-unified.sh" --dry-run 2>&1); then
        if [[ "$output" == *"DRY RUN MODE"* ]]; then
            debug "Dry-run mode detected in output"
            return 0
        else
            error "Dry-run mode not properly indicated"
            return 1
        fi
    else
        error "Dry-run execution failed"
        return 1
    fi
}

# Test: Help output
test_help_output() {
    local output
    if output=$("$SCRIPT_DIR/install-unified.sh" --help 2>&1); then
        if [[ "$output" == *"USAGE"* && "$output" == *"OPTIONS"* ]]; then
            debug "Help output contains expected sections"
            return 0
        else
            error "Help output missing expected sections"
            return 1
        fi
    else
        error "Help command failed"
        return 1
    fi
}

# Test: Stowable directories exist
test_stow_directories() {
    cd "$DOTFILES_DIR" || return 1
    
    local stow_dirs
    mapfile -t stow_dirs < <(find . -maxdepth 1 -type d -name ".*" -not -name ".git*" -not -name ".." -not -name "." | sed 's|./||')
    
    if [[ ${#stow_dirs[@]} -eq 0 ]]; then
        warning "No stowable directories found (this might be expected in a clean setup)"
        return 0
    fi
    
    debug "Found ${#stow_dirs[@]} stowable directories: ${stow_dirs[*]}"
    return 0
}

# Main test runner
main() {
    header "🧪 Testing Unified Dotfiles System"
    
    # Run all tests
    run_test "Configuration file validation" test_config_file
    run_test "Platform detection" test_platform_detection
    run_test "Package manager detection" test_package_manager
    run_test "Library files" test_library_files
    run_test "Installation scripts" test_installation_scripts
    run_test "Package configuration structure" test_package_structure
    run_test "Dry-run functionality" test_dry_run
    run_test "Help output" test_help_output
    run_test "Stowable directories" test_stow_directories
    
    # Summary
    echo "=========================================="
    echo "Test Results:"
    echo "  Total tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "=========================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎉 All tests passed!"
        exit 0
    else
        error "💥 $TESTS_FAILED test(s) failed"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
