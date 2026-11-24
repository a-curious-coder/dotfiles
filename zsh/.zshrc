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

# reminder, not auto: auto mode git-pulls mid-startup and freezes the shell.
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13

plugins=(
    git
    docker
    web-search
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
)
# Linked in by herdr's ohmyzsh.shell plugin; absent on machines without herdr.
[[ -d ${ZSH_CUSTOM:-$ZSH/custom}/plugins/herdr ]] && plugins+=(herdr)

# Single-user machine: skip compaudit's per-startup ownership scan.
ZSH_DISABLE_COMPFIX="true"

[[ -d "$ZSH" ]] && source "$ZSH/oh-my-zsh.sh"

# Version manager (replaces nvm/rbenv/pyenv). --shims: no mise.toml here uses
# [env], so the per-prompt hook (18-220ms) buys nothing; this just puts the
# shims back in front of the Homebrew dirs prepended above.
if (( $+commands[mise] )); then
    cached_init mise activate zsh --shims
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
    cached_init starship init zsh --print-full-init
fi

(( $+commands[fzf] )) && cached_init fzf --zsh
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Linux desktop sessions can keep stale Wayland variables after compositor restarts.
sync_wayland_session_environment() {
    [[ $OSTYPE == linux* ]] || return 0
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

# Internet Speed Monitor (Linux box only)
[[ -d /home/groot/scripts ]] && path+=(/home/groot/scripts)

alias cat='bat --paging=never'

# Show boot time once per login (Linux only)
if (( $+commands[systemd-analyze] )) && [[ "$SHLVL" -eq 1 ]]; then
    boot_summary=$(systemd-analyze 2>/dev/null | head -1)
    [[ -n "$boot_summary" ]] && echo "  $boot_summary"
fi

# zoxide must be initialized last so its precmd/chpwd hooks aren't clobbered.
# The doctor false-positives on the direnv hook added below (additive, no clobber).
export _ZO_DOCTOR=0
if (( $+commands[zoxide] )); then
    cached_init zoxide init zsh --cmd cd
    # Seed ~/Projects so `cd <name>` works before you've ever visited the dir.
    # Only when ~/Projects changed since the last seed: skips a db write per shell.
    _stamp="$HOME/.cache/zsh-init/zoxide-projects.stamp"
    if [[ ! -e $_stamp || ~/Projects -nt $_stamp ]]; then
        _p=(~/Projects/*(/N)); (( $#_p )) && zoxide add $_p && mkdir -p ${_stamp:h} && touch $_stamp
        unset _p
    fi
    unset _stamp
fi

direnv_bin="${commands[direnv]:-/opt/homebrew/bin/direnv}"
if [[ -x "$direnv_bin" ]]; then
    cached_init "$direnv_bin" hook zsh
    _direnv_rehash_hook() {
        rehash
    }
    add-zsh-hook precmd _direnv_rehash_hook
    add-zsh-hook chpwd _direnv_rehash_hook
    unset DIRENV_DIFF DIRENV_WATCHES
    eval "$("$direnv_bin" export zsh)"
    rehash
fi
unset direnv_bin

if [[ -d /opt/homebrew/opt/postgresql@16.10/bin ]]; then
    path=(/opt/homebrew/opt/postgresql@16.10/bin ${path:#/opt/homebrew/opt/postgresql@16.10/bin})
    export PATH
    rehash
fi

# hecaton and bun (incl. sd/seeds-cli, preliminary software) install here.
for dir in "$HOME/hecaton/bin" "$HOME/.bun/bin"; do
    [[ -d "$dir" ]] && path=("$dir" $path)
done

export PATH="$HOME/.local/bin:$PATH"

# micromamba (cached; was spawned on every start). Not `micromamba shell init`'s
# block on purpose: re-running that command will re-add the uncached version.
if [[ -x /opt/homebrew/bin/micromamba ]]; then
    export MAMBA_EXE=/opt/homebrew/bin/micromamba MAMBA_ROOT_PREFIX="$HOME/mamba"
    cached_init "$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" || alias micromamba="$MAMBA_EXE"
fi
alias p='pwd'
alias c='clear'
# a function, not an alias: an alias cannot take the port as an argument
killport() { lsof -ti "tcp:${1:?usage: killport <port>}" -sTCP:LISTEN | xargs kill; }

# clauth completions
[[ -f "$HOME/.clauth/completions/clauth.zsh" ]] && source "$HOME/.clauth/completions/clauth.zsh"

# Nourish AWS SSO helper
export PATH="${PATH}:${HOME}/bin"
function av {
    ROLE=$1
    shift
    aws-vault exec "$ROLE" -- "$@"
}

# rc <stage>: Rails console on that stage, read-only DB
rc() {
  [[ -n "$1" ]] || { echo "usage: rc <stage>"; return 1; }
  (
    builtin cd ~/Projects/work/nourish-organisations || exit 1
    local creds  # captured first: eval of empty output would return 0 and hide an expired login
    creds="$(aws configure export-credentials --profile nc --format env)" || {
      echo "run: aws sso login --profile nc"; exit 1; }
    eval "$creds"
    export SHELL=/bin/bash
    DISABLE_DB_WRITER=true bundle exec cap "$1" rails:console
  )
}

# rlog <stage> [pattern]: follow that stage's Rails log, optionally only lines matching pattern
rlog() {
  [[ -n "$1" ]] || { echo "usage: rlog <stage> [pattern]"; return 1; }
  (
    builtin cd ~/Projects/work/nourish-organisations || exit 1
    local creds  # captured first: eval of empty output would return 0 and hide an expired login
    creds="$(aws configure export-credentials --profile nc --format env)" || {
      echo "run: aws sso login --profile nc"; exit 1; }
    eval "$creds"
    export SHELL=/bin/bash
    echo "following $1 log for '${2:-everything}' (silent until a line matches, Ctrl+C to stop)"
    bundle exec cap "$1" logs:unicorn 2>&1 | rg --line-buffered -- "${2:-.}"
  )
}

# Only surface startup time when it regresses past 500ms.
if [[ -n "${ZSH_STARTUP_T0:-}" ]]; then
    _zsh_startup_ms=$(( (EPOCHREALTIME - ZSH_STARTUP_T0) * 1000 ))
    (( _zsh_startup_ms > 500 )) && printf 'zsh slow: %.0fms\n' $_zsh_startup_ms
    unset _zsh_startup_ms ZSH_STARTUP_T0
fi
