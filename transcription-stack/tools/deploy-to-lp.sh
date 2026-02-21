#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-lp}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

scp "$ROOT/scripts/local-live-dictation.py" "$HOST":~/.local/bin/local-live-dictation.py
scp "$ROOT/scripts/local-live-dictation-eval.py" "$HOST":~/.local/bin/local-live-dictation-eval.py
scp "$ROOT/scripts/hyprwhspr-double-left-ctrl.py" "$HOST":~/.local/bin/hyprwhspr-double-left-ctrl.py
scp "$ROOT/systemd/hyprwhspr-double-left-ctrl.service" "$HOST":~/.config/systemd/user/hyprwhspr-double-left-ctrl.service
scp "$ROOT/config/hyprwhspr-config.json" "$HOST":~/.config/hyprwhspr/config.json

ssh "$HOST" '
  chmod +x ~/.local/bin/local-live-dictation.py ~/.local/bin/local-live-dictation-eval.py ~/.local/bin/hyprwhspr-double-left-ctrl.py
  python3 -m py_compile ~/.local/bin/local-live-dictation.py ~/.local/bin/local-live-dictation-eval.py ~/.local/bin/hyprwhspr-double-left-ctrl.py
  systemctl --user daemon-reload
  systemctl --user restart hyprwhspr-double-left-ctrl.service
'

echo "Deployed from $ROOT -> $HOST"
