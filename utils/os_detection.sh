#!/usr/bin/env bash

# OS detection utilities
# ---------------------

function is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

function is_linux() {
    [[ "$(uname)" == "Linux" ]]
}

function is_ubuntu() {
    is_linux && [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release
}

function get_os_name() {
    if is_macos; then
        echo "macOS"
    elif is_ubuntu; then
        echo "Ubuntu"
    elif is_linux; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

