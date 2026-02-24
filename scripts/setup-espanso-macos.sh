#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Not macOS. Skipping espanso Application Support link."
  exit 0
fi

source_dir="${XDG_CONFIG_HOME:-$HOME/.config}/espanso"
target_dir="$HOME/Library/Application Support/espanso"
target_parent="$(dirname "$target_dir")"

if [[ ! -e "$source_dir" && ! -L "$source_dir" ]]; then
  echo "Espanso source config not found at $source_dir. Stow espanso first."
  exit 0
fi

mkdir -p "$target_parent"

if [[ -L "$target_dir" ]]; then
  current_target="$(readlink "$target_dir")"
  if [[ "$current_target" == "$source_dir" ]]; then
    echo "Espanso macOS config link already correct."
    exit 0
  fi
fi

if [[ -e "$target_dir" || -L "$target_dir" ]]; then
  backup_dir="${target_dir}.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$target_dir" "$backup_dir"
  echo "Backed up existing espanso config to: $backup_dir"
fi

ln -s "$source_dir" "$target_dir"
echo "Linked $target_dir -> $source_dir"
