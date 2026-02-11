#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

os_name="$(uname -s)"
case "$os_name" in
  Darwin)
    package="calibre-macos"
    config_dir="$HOME/Library/Preferences/calibre"
    ;;
  Linux)
    package="calibre-linux"
    config_dir="$HOME/.config/calibre"
    ;;
  *)
    echo "Unsupported OS: $os_name" >&2
    exit 1
    ;;
esac

mkdir -p "$config_dir"

timestamp="$(date +%Y%m%d_%H%M%S)"
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-calibre-backup/$timestamp"
moved_existing=0

while IFS= read -r src_file; do
  rel_path="${src_file#"$package/"}"
  target_path="$HOME/$rel_path"

  if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
    mkdir -p "$backup_root/$(dirname "$rel_path")"
    mv "$target_path" "$backup_root/$rel_path"
    moved_existing=1
  fi
done < <(find "$package" -type f | sort)

stow "$package"

echo "Stowed package '$package'."
echo "Calibre config location: $config_dir"
if [ "$moved_existing" -eq 1 ]; then
  echo "Backed up previous files to: $backup_root"
fi
echo "Note: Create a custom integer column in Calibre for 1-7 ratings (e.g. #rating7)."
