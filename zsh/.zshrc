autoload -U add-zsh-hook

# Interactive shell settings.
MAILCHECK=0
unset MAIL MAILPATH

# Oh My Zsh.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_MAGIC_FUNCTIONS="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"

# Keep PATH usable even when inherited PATH is empty, then layer local tools.
[[ -n "${PATH:-}" ]] || export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
typeset -U path PATH

for dir in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
    [[ -d "$dir" ]] && path=("$dir" $path)
done

for dir in /opt/homebrew/bin /opt/homebrew/sbin; do
    [[ -d "$dir" ]] && path=("$dir" $path)
done

for dir in \
    "${GOPATH:+$GOPATH/bin}" \
    "${GOROOT:+$GOROOT/bin}" \
    /snap/bin \
    /opt/nvim-linux64/bin \
    "$HOME/.lmstudio/bin"
do
    [[ -n "$dir" && -d "$dir" ]] && path+=("$dir")
done

# Optional secrets used by Codex on machines that have it installed.
if (( $+commands[codex] )) && [[ -f "$HOME/.secrets/load_codex_secrets.zsh" ]]; then
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

[[ -d "$ZSH" ]] && source "$ZSH/oh-my-zsh.sh"

# Version managers.
export NVM_DIR="$HOME/.nvm"

load_nvm() {
    [[ -s "$NVM_DIR/nvm.sh" ]] || return 0

    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
    add-zsh-hook -d preexec load_nvm
}
add-zsh-hook preexec load_nvm

if (( $+commands[rbenv] )) && [[ -z "${RBENV_SHELL:-}" ]]; then
    eval "$(rbenv init - --no-rehash zsh)"
fi

if (( $+commands[pyenv] )); then
    eval "$(pyenv init - --no-rehash)"
fi

# User extensions.
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"
[[ -f "$HOME/.zsh_functions" ]] && source "$HOME/.zsh_functions"

# History.
HISTSIZE=10000
SAVEHIST=10000
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Tooling.
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"

    cd() {
        if [[ "${1:-}" == -* ]]; then
            builtin cd "$@"
        else
            z "$@"
        fi
    }
fi

if (( $+commands[starship] )); then
    local_starship_config=""

    for candidate in \
        "$HOME/.config/starship.toml" \
        "$HOME/.config/starship-lambda.toml" \
        "$HOME/.config/starship-context.toml"
    do
        if [[ -f "$candidate" ]]; then
            local_starship_config="$candidate"
            break
        fi
    done

    [[ -n "$local_starship_config" ]] && export STARSHIP_CONFIG="$local_starship_config"
    eval "$(starship init zsh)"
fi

[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Linux desktop sessions can keep stale Wayland variables after compositor restarts.
sync_wayland_session_environment() {
    [[ "$(uname -s)" == "Linux" ]] || return 0
    [[ -z "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]] || return 0
    (( $+commands[systemctl] )) || return 0

    local key value
    while IFS='=' read -r key value; do
        case "$key" in
            HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP)
                [[ -n "$value" ]] && export "$key=$value"
                ;;
        esac
    done < <(systemctl --user show-environment 2>/dev/null)
}
sync_wayland_session_environment

# Keep tmux environment in sync with exported vars managed by ~/.zshrc.env.
sync_tmux_environment_from_zshrc_env() {
    [[ -n "${TMUX:-}" ]] || return 0

    local tmux_bin="${commands[tmux]-}"
    local env_file="$HOME/.zshrc.env"
    local managed_key="DOTFILES_ZSHRC_ENV_MANAGED"
    local parsed_vars previous_line var
    local -a current_vars previous_vars stale_vars
    local -A current_lookup

    [[ -n "$tmux_bin" && -f "$env_file" ]] || return 0

    previous_line="$("$tmux_bin" show-environment -g "$managed_key" 2>/dev/null || true)"
    if [[ "$previous_line" == "$managed_key="* ]]; then
        previous_vars=(${=${previous_line#*=}})
        previous_vars=(${previous_vars:#PATH})
    fi

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
    current_vars=(${current_vars:#PATH})

    for var in "${current_vars[@]}"; do
        current_lookup["$var"]=1
    done

    for var in "${previous_vars[@]}"; do
        (( ${+current_lookup["$var"]} )) || stale_vars+=("$var")
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

refresh_tmux_status_for_cwd() {
    [[ -n "${TMUX:-}" && -n "${commands[tmux]-}" ]] || return 0
    "${commands[tmux]}" refresh-client -S >/dev/null 2>&1 || true
}
add-zsh-hook chpwd refresh_tmux_status_for_cwd
add-zsh-hook precmd refresh_tmux_status_for_cwd
refresh_tmux_status_for_cwd
