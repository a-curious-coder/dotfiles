#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"
source "$repo_root/detect-platform.sh"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
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

# Make ruby-lsp follow each project's Ruby version automatically. Backfill
# covers Rubies mise already has installed. Idempotent (gem install is a
# no-op if ruby-lsp is already present at that version).
setup_ruby_lsp_for_mise() {
  command -v mise >/dev/null 2>&1 || {
    echo "mise not found; skipping ruby-lsp setup"
    return
  }
  command -v jq >/dev/null 2>&1 || {
    echo "jq not found; skipping ruby-lsp setup"
    return
  }

  local version
  for version in $(mise ls --installed ruby --json | jq -r '.ruby[]?.version // empty'); do
    echo "Ensuring ruby-lsp in Ruby $version..."
    mise exec "ruby@$version" -- gem install ruby-lsp \
      || echo "  warn: ruby-lsp install failed for $version (skipping)"
  done
}

main() {
  need_cmd bash
  need_cmd stow

  local platform
  platform="$(detect_platform)"

  local -a common_packages=(
    git zsh starship tmux nvim ghostty
    btop lazygit lazydocker fastfetch ripgrep
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

  echo "Setting up ruby-lsp via mise..."
  setup_ruby_lsp_for_mise

  echo "Bootstrap complete."
}

main "$@"
