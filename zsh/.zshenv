. "$HOME/.cargo/env"
export PATH="/opt/homebrew/opt/postgresql@16.10/bin:$PATH"

# Load machine-local secrets/env overrides (not tracked in git).
# Sourced here (not just .zshrc) so vars are available in ALL zsh contexts:
# interactive, non-interactive, login, non-login — including tmux run-shell
# commands, plugin hooks, and tmux-resurrect restored panes.
[[ -f "$HOME/.zshrc.env" ]] && source "$HOME/.zshrc.env"
