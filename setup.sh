#!/usr/bin/env bash

# ADHD-Friendly Setup Script with Enhanced Reliability
# ---------------------------------------------------

# Configuration
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
COLOR_INFO='\033[1;34m'
COLOR_SUCCESS='\033[1;32m'
COLOR_RESET='\033[0m'

# ADHD-Friendly Status Messages
function info_msg() {
    echo -e "${COLOR_INFO}ℹ️  $1${COLOR_RESET}"
}

function success_msg() {
    echo -e "${COLOR_SUCCESS}✅  $1${COLOR_RESET}"
}

# Dependency Check
command -v zsh >/dev/null 2>&1 || {
    echo -e "❌ Zsh not installed!\nInstall with:"
    [[ "$(uname)" == "Linux" ]] && echo "sudo apt install zsh"
    [[ "$(uname)" == "Darwin" ]] && echo "brew install zsh"
    exit 1
}

# Install Required Packages
info_msg "Checking system dependencies..."
if ! command -v git >/dev/null 2>&1; then
    info_msg "Installing git..."
    [[ "$(uname)" == "Linux" ]] && sudo apt install -y git
    [[ "$(uname)" == "Darwin" ]] && brew install git
fi

# ADHD-Optimized ZSH Setup
info_msg "Configuring ZSH plugins..."

# Clone with error handling and visual feedback
clone_plugin() {
    local repo=$1
    local dest=$2
    
    if [ ! -d "$dest" ]; then
        git clone -q --depth 1 "$repo" "$dest" && \
        success_msg "Installed $(basename $dest)" || \
        { echo -e "❌ Failed to install $(basename $dest)"; exit 1; }
    else
        info_msg "Skipping $(basename $dest) (already exists)"
    fi
}

# Install ZSH Components
clone_plugin "https://github.com/zsh-users/zsh-autosuggestions" \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"

clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" \
    "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

# Configure Wezterm with ADHD-friendly colors
info_msg "Setting up Wezterm config..."
WEZTERM_CONFIG="$HOME/.config/wezterm"
if [ ! -d "$WEZTERM_CONFIG" ]; then
    git clone -q https://github.com/KevinSilvester/wezterm-config.git "$WEZTERM_CONFIG" && \
    success_msg "Installed Wezterm config" || \
    { echo -e "❌ Failed to install Wezterm config"; exit 1; }
else
    info_msg "Wezterm config already exists - backup recommended"
fi

# ADHD-Friendly ZSH Configuration
info_msg "Updating .zshrc with ADHD optimizations..."
ZSH_AUTOSUGGEST_CONFIG=(
    "# ADHD-friendly autocomplete"
    "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#585858,bold'"
    "ZSH_AUTOSUGGEST_STRATEGY=(history completion)"
    "bindkey '^ ' autosuggest-accept"
)

if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    cat << EOF >> ~/.zshrc

# ADHD-Optimized Additions
${ZSH_AUTOSUGGEST_CONFIG[@]}
plugins+=(zsh-autosuggestions zsh-syntax-highlighting)
EOF
    success_msg "Updated .zshrc with ADHD optimizations"
else
    info_msg "zsh-autosuggestions already in .zshrc"
fi

# Final Checks
info_msg "Validating installation..."
[ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ] && \
[ -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ] && \
[ -d "$WEZTERM_CONFIG" ] && \
success_msg "Setup completed successfully! 🎉"

# ADHD-Friendly Reminder
echo -e "\n${COLOR_INFO}💡 Remember to:${COLOR_RESET}"
echo "1. Restart your terminal"
echo "2. Run 'omz reload' if using Oh My Zsh"
echo "3. Configure Wezterm colors if needed"

