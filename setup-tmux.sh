#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd stow
need_cmd git
need_cmd tmux

echo "Stowing tmux config..."
stow tmux

tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_dir/.git" ]]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
else
  echo "TPM already installed; updating..."
  git -C "$tpm_dir" pull --ff-only
fi

install_plugins="$tpm_dir/bin/install_plugins"
if [[ ! -x "$install_plugins" ]]; then
  echo "TPM install script not found: $install_plugins" >&2
  exit 1
fi

bootstrap_session="__dotfiles_tpm_bootstrap__"
cleanup_bootstrap=false
if ! tmux list-sessions >/dev/null 2>&1; then
  tmux new-session -d -s "$bootstrap_session"
  cleanup_bootstrap=true
fi

echo "Installing tmux plugins..."
"$install_plugins"

echo "Reloading tmux config..."
tmux source-file "$HOME/.tmux.conf"

if [[ "$cleanup_bootstrap" == true ]]; then
  tmux kill-session -t "$bootstrap_session" >/dev/null 2>&1 || true
fi

echo "tmux setup complete. Prefix key is Ctrl-s."
