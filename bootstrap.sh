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

main() {
  need_cmd bash
  need_cmd stow

  local platform
  platform="$(detect_platform)"

  local -a common_packages=(
    git zsh starship tmux nvim ghostty
    btop lazygit lazydocker fastfetch ripgrep vscode espanso
  )
  local -a platform_packages=()

  if [[ "$platform" == "macos" ]]; then
    platform_packages=(aerospace sketchybar calibre-macos)
  else
    platform_packages=(hypr waybar rofi ags swaync wlogout calibre-linux)
  fi

  echo "Running modern tools installer..."
  "$repo_root/install-modern-tools.sh"

  echo "Stowing common packages..."
  stow_packages "${common_packages[@]}"

  if [[ "$platform" == "macos" ]]; then
    echo "Linking espanso config for macOS..."
    "$repo_root/scripts/setup-espanso-macos.sh"
  fi

  echo "Stowing platform packages for $platform..."
  stow_packages "${platform_packages[@]}"

  echo "Running tmux bootstrap..."
  "$repo_root/setup-tmux.sh"

  echo "Bootstrap complete."
}

main "$@"
