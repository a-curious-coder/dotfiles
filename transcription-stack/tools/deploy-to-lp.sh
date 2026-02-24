#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-lp}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/.." && pwd)"

ssh "$HOST" 'mkdir -p ~/.config/local-voice-commands'

scp "$ROOT/scripts/local-live-dictation.py" "$HOST":~/.local/bin/local-live-dictation.py
scp "$ROOT/scripts/local-live-dictation-eval.py" "$HOST":~/.local/bin/local-live-dictation-eval.py
scp "$ROOT/scripts/local-live-dictation-waybar-status.py" "$HOST":~/.local/bin/local-live-dictation-waybar-status.py
scp "$ROOT/scripts/local-voice-commands.py" "$HOST":~/.local/bin/local-voice-commands.py
scp "$ROOT/scripts/hyprwhspr-double-left-ctrl.py" "$HOST":~/.local/bin/hyprwhspr-double-left-ctrl.py
scp "$ROOT/systemd/hyprwhspr-double-left-ctrl.service" "$HOST":~/.config/systemd/user/hyprwhspr-double-left-ctrl.service
scp "$ROOT/config/hyprwhspr-config.json" "$HOST":~/.config/hyprwhspr/config.json
scp "$ROOT/config/local-voice-commands-config.json" "$HOST":~/.config/local-voice-commands/config.json
scp "$REPO_ROOT/waybar/.config/waybar/config" "$HOST":~/.config/waybar/config
scp "$REPO_ROOT/waybar/.config/waybar/style.css" "$HOST":~/.config/waybar/style.css

ssh "$HOST" '
  chmod +x ~/.local/bin/local-live-dictation.py ~/.local/bin/local-live-dictation-eval.py ~/.local/bin/local-live-dictation-waybar-status.py ~/.local/bin/local-voice-commands.py ~/.local/bin/hyprwhspr-double-left-ctrl.py
  python3 -m py_compile ~/.local/bin/local-live-dictation.py ~/.local/bin/local-live-dictation-eval.py ~/.local/bin/local-live-dictation-waybar-status.py ~/.local/bin/local-voice-commands.py ~/.local/bin/hyprwhspr-double-left-ctrl.py
  systemctl --user daemon-reload
  systemctl --user restart hyprwhspr-double-left-ctrl.service
  pkill -USR2 waybar || true
'

echo "Deployed from $ROOT (+ waybar) -> $HOST"
