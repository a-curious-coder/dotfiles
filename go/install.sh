#!/usr/bin/env bash

# Go installation script
# ---------------------

# Source utility functions
source "$(dirname "$0")/../utils/colors.sh"
source "$(dirname "$0")/../utils/os_detection.sh"

install_or_update_go() {
    info_msg "Checking Go installation..."
    
    # Get the latest Go version
    LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1 | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\)/\1/')
    
    # Check if Go is installed
    if command -v go >/dev/null 2>&1; then
        CURRENT_VERSION=$(go version | awk '{print $3}')
        if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
            success_msg "Go is already up to date ($CURRENT_VERSION)"
            return 0
        else
            info_msg "Updating Go from $CURRENT_VERSION to $LATEST_VERSION"
        fi
    else
        info_msg "Installing Go $LATEST_VERSION"
    fi

    # Determine OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv*) ARCH="armv6l" ;;
    esac

    # Download and install Go
    DOWNLOAD_URL="https://go.dev/dl/${LATEST_VERSION}.${OS}-${ARCH}.tar.gz"
    info_msg "Downloading Go from $DOWNLOAD_URL"
    curl -L $DOWNLOAD_URL -o go.tar.gz

    info_msg "Removing old Go installation"
    sudo rm -rf /usr/local/go
    info_msg "Installing new Go version"
    sudo tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz

    success_msg "Go $LATEST_VERSION has been installed"
    
    # Set up fish configuration for Go
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/go.fish" << EOF
# Go configuration
set -x GOROOT /usr/local/go
set -x GOPATH \$HOME/go
fish_add_path \$GOPATH/bin \$GOROOT/bin
EOF

    success_msg "Go environment configured for fish shell"
    return 0
}

# Run the installation function
install_or_update_go

