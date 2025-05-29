#!/usr/bin/env bash

# Platform Detection Library
# ==========================
# Provides platform detection and OS-specific utilities

# Detect current platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*)    echo "windows" ;;
        MINGW*)     echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Check if running on Linux
is_linux() {
    [[ "$(detect_platform)" == "linux" ]]
}

# Check if running on macOS
is_macos() {
    [[ "$(detect_platform)" == "macos" ]]
}

# Check if running on Windows
is_windows() {
    [[ "$(detect_platform)" == "windows" ]]
}

# Get Linux distribution
get_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release &> /dev/null; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get package manager for current platform
get_package_manager() {
    if is_macos; then
        if command_exists brew; then
            echo "brew"
        else
            echo "none"
        fi
    elif is_linux; then
        local distro=$(get_linux_distro)
        case "$distro" in
            ubuntu|debian) echo "apt" ;;
            fedora|rhel|centos) echo "dnf" ;;
            arch|manjaro) echo "pacman" ;;
            opensuse*) echo "zypper" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

# Export functions
export -f detect_platform
export -f is_linux
export -f is_macos
export -f is_windows
export -f get_linux_distro
export -f command_exists
export -f get_package_manager