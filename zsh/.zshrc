autoload -U add-zsh-hook

# =============================
# Oh My Zsh Core Configuration
# =============================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disabled - using Starship prompt instead

# General Zsh Options
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_MAGIC_FUNCTIONS="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"
[[ -f "$HOME/.zshrc.env" ]] && source "$HOME/.zshrc.env"

# Oh My Zsh Update Settings
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# =============================
# Plugins
# =============================
plugins=(
  git
  docker
  web-search
  history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# =============================
# PATH Setup
# =============================
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOPATH/bin:$GOROOT/bin:/usr/local/bin:$PATH:/snap/bin:/opt/nvim-linux64/bin"

# =============================
# Language/Tool Environments
# =============================

# Node Version Manager (NVM) - Lazy load for faster shell startup
export NVM_DIR="$HOME/.nvm"
autoload -U add-zsh-hook
load_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    add-zsh-hook -d preexec load_nvm
  fi
}
add-zsh-hook preexec load_nvm

# Ruby Version Manager (rbenv)
if command -v rbenv &> /dev/null; then
  eval "$(rbenv init - zsh)"
fi

# Rust environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# =============================
# Aliases & Custom Functions
# =============================

# Load user aliases and functions if present
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions

# Docker Compose compatibility: allow 'docker-compose' to use 'docker compose' if available
alias docker-compose='docker compose'

# =============================
# History Options
# =============================
HISTSIZE=10000
SAVEHIST=10000
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# =============================
# Completion & Correction
# =============================
# Uncomment to enable auto-correction
# setopt CORRECT
# setopt CORRECT_ALL

# Fast and safe completion initialization
autoload -Uz compinit
compinit -C

# =============================
# Modern CLI Tool Integrations
# =============================

# zoxide - smarter cd
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"

    # Wrapper function for cd to use zoxide with helpful error messages
    cd() {
        # Check if user is trying to use unsupported cd flags
        if [[ "$1" =~ ^-[^L]+ ]]; then
            echo "⚠️  cd is aliased to zoxide. Use 'z' for zoxide or 'builtin cd' for native cd."
            echo "Zoxide usage: z <directory> or just cd <directory> (without flags)"
            return 1
        fi

        # Use zoxide for navigation
        z "$@"
    }
fi

# Starship prompt (comment out if using powerlevel10k)
# Uncomment to use starship instead of powerlevel10k:
if command -v starship &> /dev/null; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
fi

# fzf integration
if command -v fzf &> /dev/null; then
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# =============================
# Custom Functions
# =============================

# SSH alias
alias c='ssh -i ~/.ssh/vps-access root@2.58.82.20'

# Claude Code alias
alias marc='claude'

# Better git diff with bat
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}

# Prompt style switcher
prompt-style() {
    local style="$1"
    local config_dir="$HOME/.config"
    local available_styles=("lambda" "zen" "context")

    if [[ -z "$style" ]]; then
        echo "Available prompt styles:"
        echo "  lambda  - λ (programmer aesthetic)"
        echo "  zen     - · (ultra minimal)"
        echo "  context - λ locally, user@host on SSH"
        echo ""
        echo "Usage: prompt-style <style>"
        echo "Current style:"
        if [[ -L "$config_dir/starship.toml" ]]; then
            readlink "$config_dir/starship.toml" | sed 's/.*starship-/  /' | sed 's/\.toml.*//'
        else
            echo "  (unknown)"
        fi
        return 0
    fi

    if [[ ! " ${available_styles[@]} " =~ " ${style} " ]]; then
        echo "Error: Style '$style' not found."
        echo "Available styles: ${available_styles[@]}"
        return 1
    fi

    # Copy the selected style to the main config
    cp "$config_dir/starship-${style}.toml" "$config_dir/starship.toml"

    echo "Switched to prompt style: $style"
    echo "Reload your shell with: source ~/.zshrc"
}

# Ghostty theme switcher
ghostty-theme() {
    local theme_name="$1"
    local config_file="$HOME/.config/ghostty/config"
    local available_themes=("current" "minimalist" "dracula" "nord")

    if [[ -z "$theme_name" ]]; then
        echo "Available themes: ${available_themes[@]}"
        echo "Usage: ghostty-theme <theme-name>"
        echo "Current theme:"
        grep "^import.*theme-" "$config_file" | sed 's/.*theme-/  /' | sed 's/\.conf.*//'
        return 0
    fi

    if [[ ! " ${available_themes[@]} " =~ " ${theme_name} " ]]; then
        echo "Error: Theme '$theme_name' not found."
        echo "Available themes: ${available_themes[@]}"
        return 1
    fi

    # Comment out all theme imports
    sed -i 's/^import = \(.*theme-.*\.conf\)/# import = \1/' "$config_file"

    # Uncomment the selected theme
    sed -i "s|^# import = \(.*theme-${theme_name}\.conf\)$|import = \1|" "$config_file"

    echo "Switched to theme: $theme_name"
    echo "Note: You may need to restart Ghostty or open a new window for changes to take effect."
}

# =============================
# Neofetch
# =============================
# Display neofetch on terminal startup with custom ASCII art
# if command -v neofetch &> /dev/null; then
#     neofetch --ascii ~/.config/neofetch/ascii_art.txt --ascii_colors 4 6 2 3 5 1
# fi
