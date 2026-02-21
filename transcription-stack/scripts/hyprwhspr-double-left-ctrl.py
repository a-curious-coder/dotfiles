#!/usr/bin/env python3
"""Listen for a clean double-tap of Ctrl and toggle local live dictation."""

import os
import select
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict

try:
    from evdev import InputDevice, ecodes, list_devices
except Exception as exc:
    print(f"[double-ctrl] Failed to import evdev: {exc}", file=sys.stderr, flush=True)
    sys.exit(1)

CTRL_CODES = {ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL}
DOUBLE_TAP_WINDOW = 0.45
MAX_TAP_HOLD = 0.30
TRIGGER_COOLDOWN = 1.40
MIN_ON_SECONDS_BEFORE_STOP = 3.00
TAP_DEDUP_WINDOW = 0.07
RESCAN_INTERVAL = 5.0

LOCAL_DICTATION_CMD = "/home/groot/.local/bin/local-live-dictation.py"
UID = os.getuid()
XDG_RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{UID}")
DICTATION_PID_FILE = Path(XDG_RUNTIME_DIR) / "local-live-dictation" / "loop.pid"

RUNNING = True


def _handle_signal(_signum, _frame):
    global RUNNING
    RUNNING = False


def _is_keyboard_like(device: InputDevice) -> bool:
    name = (device.name or "").lower()

    # Ignore ydotool injected device to avoid feedback loops.
    if "ydotool" in name:
        return False

    caps = device.capabilities(verbose=False)
    keys = set(caps.get(ecodes.EV_KEY, []))

    required = {
        ecodes.KEY_LEFTCTRL,
        ecodes.KEY_A,
        ecodes.KEY_Z,
        ecodes.KEY_SPACE,
    }
    return required.issubset(keys)


def _discover_devices(devices: Dict[int, InputDevice], key_state: Dict[int, dict]) -> Dict[int, InputDevice]:
    known_paths = {dev.path for dev in devices.values()}
    for path in list_devices():
        if path in known_paths:
            continue
        try:
            dev = InputDevice(path)
            if _is_keyboard_like(dev):
                devices[dev.fd] = dev
                key_state[dev.fd] = {
                    "ctrl_is_down": False,
                    "ctrl_down_ts": 0.0,
                    "saw_other_key_during_ctrl": False,
                }
                print(f"[double-ctrl] monitoring {dev.name} ({dev.path})", flush=True)
            else:
                dev.close()
        except Exception:
            continue
    return devices


def _remove_device(fd: int, devices: Dict[int, InputDevice], key_state: Dict[int, dict]) -> None:
    dev = devices.pop(fd, None)
    key_state.pop(fd, None)
    if dev is None:
        return
    try:
        print(f"[double-ctrl] device removed {dev.name} ({dev.path})", flush=True)
        dev.close()
    except Exception:
        pass


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _dictation_running() -> bool:
    try:
        pid = int(DICTATION_PID_FILE.read_text().strip())
    except Exception:
        return False
    return _pid_alive(pid)


def _play_state_sound(on: bool) -> None:
    event_id = "service-login" if on else "complete"
    for cmd in (
        ["canberra-gtk-play", "-i", event_id],
        ["paplay", "/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"],
    ):
        try:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return
        except Exception:
            continue


def _notify(summary: str, body: str = "") -> None:
    # Best-effort desktop notification. This can fail in some session setups.
    try:
        args = ["notify-send", "-a", "Dictation", summary]
        if body:
            args.append(body)
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def _trigger_dictation(now: float, last_start_ts: float) -> float:
    running = _dictation_running()

    if running and last_start_ts > 0.0 and (now - last_start_ts) < MIN_ON_SECONDS_BEFORE_STOP:
        wait_left = max(0.0, MIN_ON_SECONDS_BEFORE_STOP - (now - last_start_ts))
        print(f"[double-ctrl] ignoring stop while dictation is still starting ({wait_left:.1f}s)", flush=True)
        _play_state_sound(True)
        _notify("Dictation", "Still starting...")
        return last_start_ts

    action = "stop" if running else "start"
    print(f"[double-ctrl] trigger -> local-live-dictation {action}", flush=True)

    out = ""
    rc = 1
    try:
        proc = subprocess.run(
            [LOCAL_DICTATION_CMD, action],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=15,
        )
        rc = proc.returncode
        out = (proc.stdout or "").strip() or (proc.stderr or "").strip()
    except Exception as exc:
        out = str(exc)

    if action == "start":
        ok = rc == 0 and out in {"started", "already-running"}
        if ok:
            _play_state_sound(True)
            _notify("Dictation On", "Live transcription enabled")
            return now
        _play_state_sound(False)
        _notify("Dictation Start Failed", out or "See log")
        print(f"[double-ctrl] start failed rc={rc} out={out}", flush=True)
        return last_start_ts

    ok = rc == 0 and out in {"stopped", "already-stopped"}
    if ok:
        _play_state_sound(False)
        _notify("Dictation Off", "Live transcription disabled")
        return 0.0

    _play_state_sound(False)
    _notify("Dictation Stop Failed", out or "See log")
    print(f"[double-ctrl] stop failed rc={rc} out={out}", flush=True)
    return last_start_ts


def main() -> int:
    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    devices: Dict[int, InputDevice] = {}
    key_state: Dict[int, dict] = {}

    last_scan = 0.0

    # Global tap timeline (dedupes mirrored keyboard devices).
    last_tap_up_ts = 0.0
    last_raw_tap_ts = 0.0
    last_trigger_ts = 0.0
    last_start_ts = 0.0

    print("[double-ctrl] started", flush=True)

    while RUNNING:
        now = time.monotonic()
        if now - last_scan >= RESCAN_INTERVAL or not devices:
            devices = _discover_devices(devices, key_state)
            last_scan = now

        if not devices:
            time.sleep(0.5)
            continue

        fds = list(devices.keys())
        try:
            ready, _, _ = select.select(fds, [], [], 0.5)
        except Exception:
            time.sleep(0.2)
            continue

        for fd in ready:
            dev = devices.get(fd)
            if dev is None:
                continue

            state = key_state.setdefault(
                fd,
                {
                    "ctrl_is_down": False,
                    "ctrl_down_ts": 0.0,
                    "saw_other_key_during_ctrl": False,
                },
            )

            try:
                events = dev.read()
            except OSError:
                _remove_device(fd, devices, key_state)
                continue

            for event in events:
                if event.type != ecodes.EV_KEY:
                    continue

                code = event.code
                value = event.value  # 0=up, 1=down, 2=hold/repeat

                if code in CTRL_CODES:
                    if value == 1:
                        if state["ctrl_is_down"]:
                            continue
                        state["ctrl_is_down"] = True
                        state["ctrl_down_ts"] = time.monotonic()
                        state["saw_other_key_during_ctrl"] = False

                    elif value == 0:
                        if not state["ctrl_is_down"]:
                            continue

                        state["ctrl_is_down"] = False
                        held = time.monotonic() - float(state["ctrl_down_ts"]) if state["ctrl_down_ts"] else 999.0
                        valid_tap = (not state["saw_other_key_during_ctrl"]) and held <= MAX_TAP_HOLD

                        if valid_tap:
                            tap_time = time.monotonic()

                            # Ignore duplicates from mirrored input devices.
                            if (tap_time - last_raw_tap_ts) < TAP_DEDUP_WINDOW:
                                state["ctrl_down_ts"] = 0.0
                                state["saw_other_key_during_ctrl"] = False
                                continue
                            last_raw_tap_ts = tap_time

                            if (
                                last_tap_up_ts > 0.0
                                and (tap_time - last_tap_up_ts) <= DOUBLE_TAP_WINDOW
                                and (tap_time - last_trigger_ts) >= TRIGGER_COOLDOWN
                            ):
                                last_start_ts = _trigger_dictation(tap_time, last_start_ts)
                                last_trigger_ts = tap_time
                                last_tap_up_ts = 0.0
                            else:
                                last_tap_up_ts = tap_time
                        else:
                            last_tap_up_ts = 0.0

                        state["ctrl_down_ts"] = 0.0
                        state["saw_other_key_during_ctrl"] = False

                else:
                    if value == 1:
                        if state["ctrl_is_down"]:
                            state["saw_other_key_during_ctrl"] = True
                        last_tap_up_ts = 0.0

    for fd in list(devices.keys()):
        _remove_device(fd, devices, key_state)

    print("[double-ctrl] stopped", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
