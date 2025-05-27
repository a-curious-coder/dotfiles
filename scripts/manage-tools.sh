#!/usr/bin/env bash

# Tool Selection Manager
# ======================
# Manage which tools to install based on tool-selection.yaml

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

# Configuration files
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${DOTFILES_DIR}/config.yaml"
SELECTION_FILE="${DOTFILES_DIR}/tool-selection.yaml"

# Ensure yq is available
install_yq() {
    if ! command -v yq &> /dev/null; then
        info "Installing yq for YAML parsing..."
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
    fi
}

# Show interactive menu for tool selection
show_selection_menu() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║                TOOL SELECTION MENU               ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo "Manage your tool installation preferences:"
    echo ""
    echo -e "${BLUE}[1]${NC} 📋 Show current selections"
    echo -e "${BLUE}[2]${NC} ⚙️  Configure tool categories"
    echo -e "${BLUE}[3]${NC} 🔧 Enable/disable individual tools"
    echo -e "${BLUE}[4]${NC} 📊 Show installation summary"
    echo -e "${BLUE}[5]${NC} 🚀 Install selected tools"
    echo -e "${BLUE}[6]${NC} 📖 What is Ghidra?"
    echo -e "${BLUE}[7]${NC} 🔧 Fix broken installations"
    echo -e "${BLUE}[q]${NC} ❌ Quit"
    echo ""
}

# Show current tool selections
show_current_selections() {
    echo -e "${YELLOW}📋 Current Tool Selections:${NC}"
    echo ""

    # Read categories and tools
    local categories=$(yq eval 'keys' "$SELECTION_FILE" | grep -v "^#" | sed 's/^- //')

    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            echo -e "${BLUE}🔹 ${category^^}:${NC}"
            local tools=$(yq eval ".${category} | keys" "$SELECTION_FILE" | sed 's/^- //')
            while IFS= read -r tool; do
                if [[ -n "$tool" ]]; then
                    local enabled=$(yq eval ".${category}.${tool}.enabled" "$SELECTION_FILE")
                    local description=$(yq eval ".${category}.${tool}.description" "$SELECTION_FILE")
                    local status_icon="${RED}✗${NC}"
                    [[ "$enabled" == "true" ]] && status_icon="${GREEN}✓${NC}"
                    echo -e "  ${status_icon} ${tool} - ${description}"
                fi
            done <<< "$tools"
            echo ""
        fi
    done <<< "$categories"
}

# Toggle category on/off
configure_categories() {
    echo -e "${YELLOW}⚙️  Configure Tool Categories:${NC}"
    echo ""

    local categories=$(yq eval 'keys' "$SELECTION_FILE" | grep -v "^#" | sed 's/^- //')
    local i=1

    # Show categories with current status
    declare -A category_map
    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            # Check if any tools in category are enabled
            local enabled_count=$(yq eval ".${category} | to_entries | map(select(.value.enabled == true)) | length" "$SELECTION_FILE")
            local total_count=$(yq eval ".${category} | length" "$SELECTION_FILE")
            local status="[${enabled_count}/${total_count}]"

            echo -e "${BLUE}[$i]${NC} ${category} ${status}"
            category_map[$i]="$category"
            i=$((i + 1))
        fi
    done <<< "$categories"

    echo ""
    echo "Enter category number to toggle all tools in that category (or 'back'):"
    read -r selection

    if [[ "$selection" == "back" ]]; then
        return
    fi

    if [[ -n "${category_map[$selection]:-}" ]]; then
        local category="${category_map[$selection]}"
        echo ""
        echo "Toggle all tools in '$category' category:"
        echo -e "${BLUE}[1]${NC} Enable all"
        echo -e "${BLUE}[2]${NC} Disable all"
        echo -e "${BLUE}[3]${NC} Back"
        read -r action

        case "$action" in
            1)
                yq eval ".${category}[] |= .enabled = true" -i "$SELECTION_FILE"
                success "Enabled all tools in '$category' category"
                ;;
            2)
                yq eval ".${category}[] |= .enabled = false" -i "$SELECTION_FILE"
                success "Disabled all tools in '$category' category"
                ;;
            3|*)
                return
                ;;
        esac
    else
        warning "Invalid selection"
    fi
}

# Configure individual tools
configure_individual_tools() {
    echo -e "${YELLOW}🔧 Configure Individual Tools:${NC}"
    echo ""

    local categories=$(yq eval 'keys' "$SELECTION_FILE" | grep -v "^#" | sed 's/^- //')
    local all_tools=()
    local i=1

    # Create a flat list of all tools
    declare -A tool_map
    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            local tools=$(yq eval ".${category} | keys" "$SELECTION_FILE" | sed 's/^- //')
            while IFS= read -r tool; do
                if [[ -n "$tool" ]]; then
                    local enabled=$(yq eval ".${category}.${tool}.enabled" "$SELECTION_FILE")
                    local description=$(yq eval ".${category}.${tool}.description" "$SELECTION_FILE")
                    local status_icon="${RED}✗${NC}"
                    [[ "$enabled" == "true" ]] && status_icon="${GREEN}✓${NC}"

                    echo -e "${BLUE}[$i]${NC} ${status_icon} ${tool} - ${description}"
                    tool_map[$i]="${category}.${tool}"
                    i=$((i + 1))
                fi
            done <<< "$tools"
        fi
    done <<< "$categories"

    echo ""
    echo "Enter tool number to toggle (or 'back'):"
    read -r selection

    if [[ "$selection" == "back" ]]; then
        return
    fi

    if [[ -n "${tool_map[$selection]:-}" ]]; then
        local tool_path="${tool_map[$selection]}"
        local current_state=$(yq eval ".${tool_path}.enabled" "$SELECTION_FILE")
        local new_state="false"
        [[ "$current_state" == "false" ]] && new_state="true"

        yq eval ".${tool_path}.enabled = ${new_state}" -i "$SELECTION_FILE"
        local tool_name=$(echo "$tool_path" | cut -d'.' -f2)
        success "Toggled $tool_name to: $new_state"
    else
        warning "Invalid selection"
    fi
}

# Show installation summary
show_installation_summary() {
    echo -e "${YELLOW}📊 Installation Summary:${NC}"
    echo ""

    local total_enabled=0
    local total_tools=0
    local categories=$(yq eval 'keys' "$SELECTION_FILE" | grep -v "^#" | sed 's/^- //')

    while IFS= read -r category; do
        if [[ -n "$category" ]]; then
            local enabled_count=$(yq eval ".${category} | to_entries | map(select(.value.enabled == true)) | length" "$SELECTION_FILE")
            local total_count=$(yq eval ".${category} | length" "$SELECTION_FILE")

            total_enabled=$((total_enabled + enabled_count))
            total_tools=$((total_tools + total_count))

            echo -e "${BLUE}${category^^}:${NC} ${enabled_count}/${total_count} tools enabled"
        fi
    done <<< "$categories"

    echo ""
    echo -e "${GREEN}Total: ${total_enabled}/${total_tools} tools selected for installation${NC}"

    # Estimate installation size and time
    local size_mb=$((total_enabled * 50))  # Rough estimate
    local time_min=$((total_enabled * 2))  # Rough estimate

    echo ""
    echo -e "${CYAN}Estimated download size: ~${size_mb}MB${NC}"
    echo -e "${CYAN}Estimated installation time: ~${time_min} minutes${NC}"
}

# Install selected tools
install_selected_tools() {
    echo -e "${YELLOW}🚀 Installing Selected Tools:${NC}"
    echo ""

    # Count enabled tools
    local enabled_tools=$(yq eval '.. | select(has("enabled")) | select(.enabled == true)' "$SELECTION_FILE" | yq eval 'length')

    if [[ "$enabled_tools" == "0" ]]; then
        warning "No tools selected for installation!"
        return 1
    fi

    echo -e "${GREEN}Found ${enabled_tools} tools to install${NC}"
    echo ""
    echo "Do you want to proceed? (y/N):"
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        info "Starting installation..."
        # Call the main installation script with selected tools
        "${DOTFILES_DIR}/install-interactive.sh"
    else
        info "Installation cancelled"
    fi
}

# Explain what Ghidra is
explain_ghidra() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════╗
║                WHAT IS GHIDRA?                   ║
╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    cat << "EOF"
🔍 Ghidra is a powerful reverse engineering tool developed by the NSA
   and released as open-source software in 2019.

📋 What it does:
   • Disassembles binary files (executables, firmware, etc.)
   • Provides a graphical interface for analyzing code
   • Helps understand how programs work without source code
   • Useful for malware analysis, vulnerability research, and CTFs

🎯 Common use cases:
   • Security research and vulnerability analysis
   • Malware reverse engineering
   • CTF (Capture The Flag) competitions
   • Understanding proprietary software
   • Firmware analysis

🏆 Why it's valuable:
   • Free alternative to expensive tools like IDA Pro
   • Supports many processor architectures
   • Extensible with scripts and plugins
   • Industry-standard tool used by security professionals

🚀 Getting started:
   • Launch with: ghidra
   • Import a binary file to analyze
   • Use the code browser to explore disassembled code
   • Check online tutorials for detailed usage

⚠️  Note: Ghidra requires Java and can be resource-intensive.
   Make sure you have at least 4GB RAM available.

EOF

    echo ""
    echo "Would you like to enable Ghidra installation? (y/N):"
    read -r enable_ghidra

    if [[ "$enable_ghidra" =~ ^[Yy]$ ]]; then
        yq eval '.security.ghidra.enabled = true' -i "$SELECTION_FILE"
        success "Ghidra enabled for installation"
    fi
}

# Fix broken installations
fix_broken_installations() {
    echo -e "${YELLOW}🔧 Fixing Broken Installations:${NC}"
    echo ""

    echo "Checking and fixing common issues..."

    # Fix Burp Suite symlink
    if [[ -f "/opt/burpsuite/BurpSuiteCommunity" ]]; then
        info "Fixing Burp Suite symlink..."
        sudo ln -sf "/opt/burpsuite/BurpSuiteCommunity" "/usr/local/bin/burpsuite"
        success "Burp Suite symlink fixed"
    fi

    # Check Ghidra installation
    if [[ ! -f "/opt/ghidra/ghidraRun" ]]; then
        warning "Ghidra not properly installed"
        echo "Would you like to install Ghidra now? (y/N):"
        read -r install_ghidra
        if [[ "$install_ghidra" =~ ^[Yy]$ ]]; then
            install_ghidra_properly
        fi
    else
        success "Ghidra installation looks good"
    fi

    # Fix rbenv PATH
    if [[ -d "${HOME}/.rbenv" ]] && ! grep -q "rbenv" "${HOME}/.zshrc"; then
        info "Adding rbenv to .zshrc..."
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "${HOME}/.zshrc"
        echo 'eval "$(rbenv init -)"' >> "${HOME}/.zshrc"
        success "rbenv PATH fixed"
    fi

    success "Broken installation fixes completed"
}

# Install Ghidra properly
install_ghidra_properly() {
    info "Installing Ghidra..."

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Download latest Ghidra
    info "Downloading Ghidra (this may take a while)..."
    wget -q --show-progress "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.1.2_build/ghidra_11.1.2_PUBLIC_20240709.zip"

    info "Extracting Ghidra..."
    unzip -q ghidra_*.zip

    info "Installing to /opt/ghidra..."
    sudo rm -rf /opt/ghidra
    sudo mv ghidra_* /opt/ghidra
    sudo chmod +x /opt/ghidra/ghidraRun

    # Create symlink
    sudo ln -sf /opt/ghidra/ghidraRun /usr/local/bin/ghidra

    cd /
    rm -rf "$temp_dir"

    success "Ghidra installed successfully"
    info "Launch with: ghidra"
}

# Main menu loop
main() {
    install_yq

    while true; do
        show_selection_menu
        echo -n "Enter your choice: "
        read -r choice

        case "$choice" in
            1)
                show_current_selections
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            2)
                configure_categories
                ;;
            3)
                configure_individual_tools
                ;;
            4)
                show_installation_summary
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            5)
                install_selected_tools
                ;;
            6)
                explain_ghidra
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            7)
                fix_broken_installations
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            q|Q)
                info "Goodbye! 👋"
                exit 0
                ;;
            *)
                warning "Invalid choice. Please try again."
                ;;
        esac
    done
}

main "$@"
