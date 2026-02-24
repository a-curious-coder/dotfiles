#!/usr/bin/env python3
"""Waybar status module for local live dictation daemon/typing state."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Optional


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _read_pid(path: Path) -> Optional[int]:
    if not path.exists():
        return None
    try:
        return int(path.read_text().strip())
    except Exception:
        return None


def main() -> int:
    uid = os.getuid()
    xdg_runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{uid}")
    state_dir = Path(xdg_runtime_dir) / "local-live-dictation"
    pid_file = state_dir / "loop.pid"
    typing_file = state_dir / "typing.on"
    command_pid_file = Path(xdg_runtime_dir) / "local-voice-commands" / "loop.pid"

    pid = _read_pid(pid_file)
    running = bool(pid and _pid_alive(pid))
    typing = running and typing_file.exists()
    command_pid = _read_pid(command_pid_file)
    command_mode = bool(command_pid and _pid_alive(command_pid))

    if command_mode:
        text = ""
        classes = ["commands", "on"]
        alt = "commands"
        tooltip = "Voice command mode enabled\nR-Ctrl x2: toggle commands\nL-Ctrl x2: switch to dictation"
    elif typing:
        text = ""
        classes = ["running", "typing", "on"]
        alt = "on"
        tooltip = "Dictation typing enabled\nL-Ctrl x2: toggle typing\nR-Ctrl x2: voice commands\nRight-click: stop daemon"
    elif running:
        text = ""
        classes = ["running", "warm"]
        alt = "warm"
        tooltip = "Dictation model loaded (typing off)\nL-Ctrl x2: enable typing\nR-Ctrl x2: voice commands\nRight-click: stop daemon"
    else:
        text = ""
        classes = ["stopped", "off"]
        alt = "off"
        tooltip = "Dictation daemon stopped\nMiddle-click: start daemon"

    out = {
        "text": text,
        "alt": alt,
        "class": classes,
        "tooltip": tooltip,
    }
    print(json.dumps(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
