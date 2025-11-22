autoload -U add-zsh-hook

# =============================
# Oh My Zsh Core Configuration
# =============================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# General Zsh Options
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_MAGIC_FUNCTIONS="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"

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
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOPATH/bin:$GOROOT/bin:/usr/local/bin:$PATH:/snap/bin:/opt/nvim-linux64/bin:/usr/lib/emscripten"

# Ripgrep config
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgreprc"


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

# zoxide - smarter cd (replaces cd command)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# Starship prompt (comment out if using powerlevel10k)
# Uncomment to use starship instead of powerlevel10k:
# if command -v starship &> /dev/null; then
#     eval "$(starship init zsh)"
# fi

# fzf integration
if command -v fzf &> /dev/null; then
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# =============================
# Custom Functions
# =============================

# SSH alias
alias c='ssh -i ~/.ssh/vps-access root@2.58.82.20'
alias g='eval "$(ssh-agent -s)" | ssh-add ~/.ssh/github-key'

# Better git diff with bat
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}
