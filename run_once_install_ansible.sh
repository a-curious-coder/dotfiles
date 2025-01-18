#!/bin/bash

# Function to install Ansible on Fedora
install_on_fedora() {
    sudo dnf install -y ansible
}

# Function to install Ansible on Ubuntu
install_on_ubuntu() {
    sudo apt-get update
    sudo apt-get install -y ansible
}

# Function to install Ansible on macOS
install_on_mac() {
    brew install ansible
}

# Detect the operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        # Check for specific Linux distributions
        if [ -f /etc/fedora-release ]; then
            # Install on Fedora
            install_on_fedora
        elif [ -f /etc/lsb-release ]; then
            # Install on Ubuntu
            install_on_ubuntu
        else
            # Unsupported Linux distribution
            echo "Unsupported Linux distribution"
            exit 1
        fi
        ;;
    Darwin*)
        # Install on macOS
        install_on_mac
        ;;
    *)
        # Unsupported operating system
        echo "Unsupported operating system: ${OS}"
        exit 1
        ;;
esac

# Run bootstrap playbook with sudo privileges
# ansible-playbook ~/.bootstrap/setup.yml --ask-become-pass

# Confirm installation
echo "Ansible installation complete."

