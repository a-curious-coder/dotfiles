autoload -U add-zsh-hook

# Suppress login banner and mail notifications
[[ -f "$HOME/.hushlogin" ]] || touch "$HOME/.hushlogin"
MAILCHECK=0
unset MAIL MAILPATH

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # using Starship instead

# Zsh behavior - explicitness over magic
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_MAGIC_FUNCTIONS="true"  # prevent pasted URLs from being escaped
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"  # faster git status in large repos
HIST_STAMPS="yyyy-mm-dd"  # ISO 8601
[[ -f "$HOME/.zshrc.env" ]] && source "$HOME/.zshrc.env"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

plugins=(
  git
  docker
  web-search
  history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOPATH/bin:$GOROOT/bin:/usr/local/bin:$PATH:/snap/bin:/opt/nvim-linux64/bin"

# NVM - lazy-loaded to avoid 200ms startup penalty
export NVM_DIR="$HOME/.nvm"
load_nvm() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    add-zsh-hook -d preexec load_nvm
  fi
}
add-zsh-hook preexec load_nvm

# rbenv
command -v rbenv &> /dev/null && eval "$(rbenv init - zsh)"

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Aliases and functions
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions

# History - share across sessions, deduplicate
HISTSIZE=10000
SAVEHIST=10000
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion - use cached dump for speed
autoload -Uz compinit
compinit -C

# zoxide - frecency-based directory jumping
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"

    cd() {
        if [[ "$1" =~ ^-[^L]+ ]]; then
            echo "cd is aliased to zoxide. Use 'builtin cd' for native cd."
            return 1
        fi
        z "$@"
    }
fi

# Starship prompt
if command -v starship &> /dev/null; then
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    eval "$(starship init zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Personal shortcuts
alias c='ssh -i ~/.ssh/vps-access root@2.58.82.20'
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
