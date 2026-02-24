#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-lp}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$ROOT/scripts" "$ROOT/systemd" "$ROOT/config" "$ROOT/notes"

scp "$HOST":~/.local/bin/local-live-dictation.py "$ROOT/scripts/local-live-dictation.py"
scp "$HOST":~/.local/bin/local-live-dictation-eval.py "$ROOT/scripts/local-live-dictation-eval.py"
scp "$HOST":~/.local/bin/local-live-dictation-waybar-status.py "$ROOT/scripts/local-live-dictation-waybar-status.py"
scp "$HOST":~/.local/bin/local-voice-commands.py "$ROOT/scripts/local-voice-commands.py"
scp "$HOST":~/.local/bin/hyprwhspr-double-left-ctrl.py "$ROOT/scripts/hyprwhspr-double-left-ctrl.py"
scp "$HOST":~/.config/systemd/user/hyprwhspr-double-left-ctrl.service "$ROOT/systemd/hyprwhspr-double-left-ctrl.service"
scp "$HOST":~/.config/hyprwhspr/config.json "$ROOT/config/hyprwhspr-config.json"
scp "$HOST":~/.config/local-voice-commands/config.json "$ROOT/config/local-voice-commands-config.json"

(
  cd "$ROOT"
  shasum -a 256 \
    scripts/local-live-dictation.py \
    scripts/local-live-dictation-eval.py \
    scripts/local-live-dictation-waybar-status.py \
    scripts/local-voice-commands.py \
    scripts/hyprwhspr-double-left-ctrl.py \
    systemd/hyprwhspr-double-left-ctrl.service \
    config/hyprwhspr-config.json \
    config/local-voice-commands-config.json > notes/latest.sha256
)

echo "Synced from $HOST -> $ROOT"
