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

detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

stow_packages() {
  local package
  for package in "$@"; do
    if [[ -d "$repo_root/$package" ]]; then
      echo "Stowing $package..."
      stow "$package"
    else
      echo "Skipping missing package: $package"
    fi
  done
}

# Make ruby-lsp follow each project's Ruby version automatically. The stowed
# ~/.rbenv/default-gems lists the gems; this plugin installs them into every
# `rbenv install`. Backfill covers Rubies already on disk. Idempotent.
setup_rbenv_default_gems() {
  command -v rbenv >/dev/null 2>&1 || {
    echo "rbenv not found; skipping ruby-lsp setup"
    return
  }

  local plugin="$(rbenv root)/plugins/rbenv-default-gems"
  if [[ ! -d "$plugin" ]]; then
    echo "Installing rbenv-default-gems plugin..."
    git clone --depth 1 https://github.com/rbenv/rbenv-default-gems.git "$plugin"
  fi

  local version
  for version in $(rbenv versions --bare 2>/dev/null); do
    echo "Ensuring ruby-lsp in Ruby $version..."
    RBENV_VERSION="$version" rbenv exec gem install ruby-lsp \
      || echo "  warn: ruby-lsp install failed for $version (skipping)"
  done
  rbenv rehash
}

main() {
  need_cmd bash
  need_cmd stow

  local platform
  platform="$(detect_platform)"

  local -a common_packages=(
    git zsh starship tmux nvim ghostty
    btop lazygit lazydocker fastfetch ripgrep rbenv
  )
  local -a platform_packages=()

  if [[ "$platform" == "linux" ]]; then
    platform_packages=(hypr kanshi waybar rofi swaync wlogout calibre-linux)
  fi

  echo "Running modern tools installer..."
  "$repo_root/install-modern-tools.sh"

  echo "Stowing common packages..."
  stow_packages "${common_packages[@]}"

  if [[ "${#platform_packages[@]}" -gt 0 ]]; then
    echo "Stowing platform packages for $platform..."
    stow_packages "${platform_packages[@]}"
  fi

  echo "Running tmux bootstrap..."
  "$repo_root/setup-tmux.sh"

  echo "Setting up ruby-lsp via rbenv-default-gems..."
  setup_rbenv_default_gems

  echo "Bootstrap complete."
}

main "$@"
