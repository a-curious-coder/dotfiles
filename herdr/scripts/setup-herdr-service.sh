#!/usr/bin/env bash
# Installs and enables the herdr server as a systemd --user service, so
# sessions/workspaces survive a reboot instead of dying with the terminal
# that launched them. Run this yourself: it uses sudo for enable-linger.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_SRC="$REPO_DIR/systemd/herdr.service"
UNIT_DST_DIR="$HOME/.config/systemd/user"

mkdir -p "$UNIT_DST_DIR"
cp "$UNIT_SRC" "$UNIT_DST_DIR/herdr.service"

systemctl --user daemon-reload
systemctl --user enable --now herdr.service

# Lets the service start at boot even before you log in graphically.
sudo loginctl enable-linger "$USER"

echo "herdr.service installed and enabled."
systemctl --user status herdr.service --no-pager
