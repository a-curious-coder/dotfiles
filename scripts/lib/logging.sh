#!/usr/bin/env bash

# Logging Library
# ===============
# Provides colored logging functions for scripts

# Prevent multiple includes
if [[ "${LOGGING_LIB_LOADED:-}" == "true" ]]; then
    return 0
fi
export LOGGING_LIB_LOADED=true

# Colors
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly PURPLE='\033[0;35m'
    readonly NC='\033[0m' # No Color
fi

# Logging functions
info() { 
    echo -e "${BLUE}[INFO]${NC} $1" 
}

success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
}

warning() { 
    echo -e "${YELLOW}[WARNING]${NC} $1" 
}

error() { 
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}

# Progress indicators
spinner() {
    local -r chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local -r delay=0.1
    local temp
    while :; do
        for (( i=0; i<${#chars}; i++ )); do
            sleep $delay
            printf ' [%s] %s\r' "${chars:$i:1}" "$1"
        done
    done &
    SPINNER_PID=$!
    disown
}

stop_spinner() {
    if [[ -n "${SPINNER_PID:-}" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        printf '\r%*s\r' "${#1}" ' '
        unset SPINNER_PID
    fi
}

# Export functions
export -f info success warning error debug spinner stop_spinner