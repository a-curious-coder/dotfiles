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

# Ensure core system tools are always reachable, even if parent env PATH is empty (e.g. fresh tmux server).
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
[[ -f "$HOME/.zshrc.env" ]] && source "$HOME/.zshrc.env"

# Codex MCP secrets (only if codex exists on this machine)
if command -v codex &> /dev/null && [[ -f "$HOME/.secrets/load_codex_secrets.zsh" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.secrets/load_codex_secrets.zsh"
fi

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

source "$ZSH/oh-my-zsh.sh"

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:${GOPATH:+$GOPATH/bin}:${GOROOT:+$GOROOT/bin}:$PATH:/snap/bin:/opt/nvim-linux64/bin"

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
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    elif [[ -f "$HOME/.config/starship-context.toml" ]]; then
        export STARSHIP_CONFIG="$HOME/.config/starship-context.toml"
    fi
    eval "$(starship init zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Optional machine-local overrides (not tracked in this repo)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Keep tmux server env aligned with vars managed in ~/.zshrc.env.
sync_tmux_environment_from_zshrc_env() {
    [[ -n "${TMUX:-}" ]] || return 0
    local tmux_bin="${commands[tmux]-}"
    if [[ -z "$tmux_bin" ]]; then
        local candidate
        for candidate in /opt/homebrew/bin/tmux /usr/local/bin/tmux /usr/bin/tmux; do
            if [[ -x "$candidate" ]]; then
                tmux_bin="$candidate"
                break
            fi
        done
    fi
    [[ -n "$tmux_bin" ]] || return 0

    local env_file="$HOME/.zshrc.env"
    local managed_key="DOTFILES_ZSHRC_ENV_MANAGED"
    local previous_line parsed_vars var
    local -a current_vars previous_vars stale_vars
    local -A current_lookup

    previous_line="$("$tmux_bin" show-environment -g "$managed_key" 2>/dev/null || true)"
    if [[ "$previous_line" == "$managed_key="* ]]; then
        previous_vars=(${=${previous_line#*=}})
    fi
    previous_vars=(${previous_vars:#PATH})

    if [[ -f "$env_file" ]]; then
        parsed_vars="$(awk '
          /^[[:space:]]*export[[:space:]]+/ {
            for (i = 2; i <= NF; ++i) {
              split($i, parts, "=")
              if (parts[1] ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print parts[1]
            }
          }
          /^[[:space:]]*typeset[[:space:]]+-[[:alnum:]]*x[[:alnum:]]*[[:space:]]+/ {
            for (i = 3; i <= NF; ++i) {
              split($i, parts, "=")
              if (parts[1] ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print parts[1]
            }
          }
          /^[[:space:]]*unset[[:space:]]+/ {
            for (i = 2; i <= NF; ++i) {
              if ($i ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print $i
            }
          }
        ' "$env_file" 2>/dev/null)"
        current_vars=(${(u)${(f)parsed_vars}})
    fi
    current_vars=(${current_vars:#PATH})

    for var in "${current_vars[@]}"; do
        current_lookup["$var"]=1
    done

    for var in "${previous_vars[@]}"; do
        [[ -n "${current_lookup[$var]-}" ]] || stale_vars+=("$var")
    done

    for var in "${stale_vars[@]}"; do
        unset -v "$var" >/dev/null 2>&1 || true
        "$tmux_bin" set-environment -gr "$var" >/dev/null 2>&1 || true
    done

    for var in "${current_vars[@]}"; do
        if [[ -n "${(P)var+set}" ]]; then
            "$tmux_bin" set-environment -g "$var" "${(P)var}" >/dev/null 2>&1 || true
        else
            "$tmux_bin" set-environment -gr "$var" >/dev/null 2>&1 || true
        fi
    done

    if (( ${#current_vars[@]} > 0 )); then
        "$tmux_bin" set-environment -g "$managed_key" "${(j: :)current_vars}" >/dev/null 2>&1 || true
    else
        "$tmux_bin" set-environment -gu "$managed_key" >/dev/null 2>&1 || true
    fi
}
sync_tmux_environment_from_zshrc_env

# Better git diff with bat
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}

# Prompt style switcher
prompt-style() {
    local style="$1"
    local config_dir="$HOME/.config"

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
        elif [[ -f "$config_dir/starship.toml" ]]; then
            local detected="custom"
            local candidate
            for candidate in lambda zen context; do
                if cmp -s "$config_dir/starship.toml" "$config_dir/starship-${candidate}.toml"; then
                    detected="$candidate"
                    break
                fi
            done
            echo "  $detected"
        else
            echo "  (unknown)"
        fi
        return 0
    fi

    case "$style" in
        lambda|zen|context) ;;
        *)
            echo "Error: Style '$style' not found."
            echo "Available styles: lambda zen context"
            return 1
            ;;
    esac

    if [[ ! -f "$config_dir/starship-${style}.toml" ]]; then
        echo "Error: Missing file $config_dir/starship-${style}.toml"
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

    if [[ -z "$theme_name" ]]; then
        echo "Available themes: current minimalist dracula nord"
        echo "Usage: ghostty-theme <theme-name>"
        echo "Current theme:"
        if [[ ! -f "$config_file" ]]; then
            echo "  (config not found)"
            return 1
        fi
        local current_theme
        current_theme="$(grep -E "^import = .*theme-.*\\.conf$" "$config_file" | sed 's/.*theme-//' | sed 's/\.conf$//' | tail -n 1)"
        if [[ -n "$current_theme" ]]; then
            echo "  $current_theme"
        else
            echo "  (no theme import configured)"
        fi
        return 0
    fi

    case "$theme_name" in
        current|minimalist|dracula|nord) ;;
        *)
            echo "Error: Theme '$theme_name' not found."
            echo "Available themes: current minimalist dracula nord"
            return 1
            ;;
    esac

    if [[ ! -f "$config_file" ]]; then
        echo "Error: Ghostty config not found at $config_file"
        return 1
    fi

    local theme_file="$HOME/.config/ghostty/themes/theme-${theme_name}.conf"
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme file not found at $theme_file"
        return 1
    fi

    local tmp_file
    tmp_file="$(mktemp)"
    awk '!/^import = .*theme-.*\.conf$/' "$config_file" > "$tmp_file"
    printf '\nimport = %s\n' "$theme_file" >> "$tmp_file"
    mv "$tmp_file" "$config_file"

    echo "Switched to theme: $theme_name"
    echo "Note: You may need to restart Ghostty or open a new window for changes to take effect."
}
if command -v pyenv 1>/dev/null 2>&1; then
    # Avoid per-shell startup rehash lock contention in new tmux panes/windows.
    eval "$(pyenv init - --no-rehash)"
fi
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
