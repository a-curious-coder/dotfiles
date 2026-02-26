#!/usr/bin/env bash
set -euo pipefail

AERO_BIN="${AEROSPACE_BIN:-aerospace}"

if ! command -v "$AERO_BIN" >/dev/null 2>&1; then
  exit 1
fi

target_workspace_for_app() {
  case "$1" in
    # Hypr tag "browser" -> workspace 1
    com.brave.Browser|com.google.Chrome|org.mozilla.firefox|com.apple.Safari) echo "1" ;;
    # Hypr tag "terminal" -> workspace 2
    com.mitchellh.ghostty|com.googlecode.iterm2|net.kovidgoyal.kitty|org.alacritty) echo "2" ;;
    # Hypr Obsidian/screenshare rules -> workspace 4
    md.obsidian|com.obsproject.obs-studio) echo "4" ;;
    # IDE/projects + file manager -> workspace 3
    com.microsoft.VSCode|com.apple.finder) echo "3" ;;
    # Hypr tag "gamestore" -> workspace 5
    com.valvesoftware.steam|com.heroicgameslauncher.hgl) echo "5" ;;
    # Hypr virt-manager rule -> workspace 6
    org.virt-manager) echo "6" ;;
    # Hypr tag "im" -> workspace 7
    com.hnc.Discord|com.microsoft.teams2|org.telegram.desktop|com.microsoft.Outlook) echo "7" ;;
    # Hypr multimedia rule -> workspace 9
    com.spotify.client) echo "9" ;;
    *) return 1 ;;
  esac
}

normalize_layout_for_app() {
  "$AERO_BIN" layout tiling >/dev/null 2>&1 || true
}

focused_window_id="$($AERO_BIN list-windows --focused --format '%{window-id}' 2>/dev/null || true)"

while IFS=$'\t' read -r window_id app_id workspace; do
  [ -n "${window_id:-}" ] || continue
  [ -n "${app_id:-}" ] || continue

  target_workspace="$(target_workspace_for_app "$app_id" 2>/dev/null || true)"
  [ -n "$target_workspace" ] || continue

  # Keep managed apps in tiling mode when reapplying startup/manual rules.
  "$AERO_BIN" focus --window-id "$window_id" >/dev/null 2>&1 || true
  normalize_layout_for_app
  if [ "$workspace" != "$target_workspace" ]; then
    "$AERO_BIN" move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
    "$AERO_BIN" focus --window-id "$window_id" >/dev/null 2>&1 || true
    normalize_layout_for_app
  fi
done < <(
  "$AERO_BIN" list-windows --monitor all --format '%{window-id}%{tab}%{app-bundle-id}%{tab}%{workspace}' 2>/dev/null
)

if [ -n "$focused_window_id" ]; then
  "$AERO_BIN" focus --window-id "$focused_window_id" >/dev/null 2>&1 || true
fi
