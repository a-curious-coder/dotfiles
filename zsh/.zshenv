zmodload zsh/datetime; ZSH_STARTUP_T0=$EPOCHREALTIME

# Source a tool's `init`-style output from a cache file instead of spawning it
# every startup; regenerates when the tool's binary is newer than the cache.
# Reset manually with: rm -rf ~/.cache/zsh-init
cached_init() {
    local bin="${commands[$1]:-$1}"; shift
    local cache="$HOME/.cache/zsh-init/${bin:t}-${${(j:-:)@}//\//_}.zsh"
    if [[ ! -s "$cache" || "$bin" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        "$bin" "$@" > "$cache" 2>/dev/null || { rm -f "$cache"; return 1; }
    fi
    source "$cache"
}

. "$HOME/.cargo/env"
export PATH="/opt/homebrew/opt/postgresql@16.10/bin:$PATH"

# Load machine-local secrets/env overrides (not tracked in git).
# Sourced here (not just .zshrc) so vars are available in ALL zsh contexts:
# interactive, non-interactive, login, non-login — including tmux run-shell
# commands, plugin hooks, and tmux-resurrect restored panes.
[[ -f "$HOME/.zshrc.env" ]] && source "$HOME/.zshrc.env"
