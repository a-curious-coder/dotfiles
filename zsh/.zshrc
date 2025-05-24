# Modern Zsh Configuration
# =======================

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Oh My Zsh settings
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"

# Update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Plugin Configuration
plugins=(
    git
    docker
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
    web-search
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Environment Variables
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch $(uname -m)"
export EDITOR='nvim'
export GOPATH="$HOME/go"
export GOROOT="/usr/local/go"

# Path Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$PATH:/snap/bin"
export PATH="$PATH:/opt/nvim-linux64/bin"

# Load aliases and functions
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Ruby Version Manager (rbenv)
export PATH="$HOME/.rbenv/shims:$PATH"
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init - zsh)"
fi

# Rust environment
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Load Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS

# Auto-correction and completion
setopt CORRECT
setopt CORRECT_ALL

# Better completion
autoload -U compinit
compinit


