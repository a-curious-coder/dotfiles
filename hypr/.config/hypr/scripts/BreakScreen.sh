#!/usr/bin/env bash
# Minimal break-screen launcher for hyprlock.
# --random (default): choose a random minimal theme.
# --fixed: use one consistent theme each time.

set -euo pipefail

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

THEME_DIR="$HOME/.config/hypr/breakthemes"
FALLBACK="$HOME/.config/hypr/hyprbreak.conf"
DEFAULT_FIXED_THEME="noir-orbit"

themes=(
    "noir-orbit"
    "noir-grid"
    "paper-ink"
    "slate-accent"
)

mode="${1:---random}"
requested_theme="${2:-}"
case "$mode" in
    --random) ;;
    --fixed) ;;
    *) mode="--random" ;;
esac

if [[ "$mode" == "--fixed" ]]; then
    if [[ -n "$requested_theme" ]]; then
        selected="$requested_theme"
    else
        selected="${HYPR_BREAK_THEME:-$DEFAULT_FIXED_THEME}"
    fi
else
    selected="${themes[RANDOM % ${#themes[@]}]}"
fi

config="$THEME_DIR/$selected.conf"
if [[ ! -f "$config" ]]; then
    config="$FALLBACK"
fi

exec hyprlock -c "$config"
