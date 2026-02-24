#!/usr/bin/env python3
"""Double-Ctrl mode switcher.

Hotkeys:
- Double LEFT Ctrl: toggle live dictation typing mode.
- Double RIGHT Ctrl: toggle voice-command mode.

Modes are strictly mutually exclusive. Starting one mode stops the other first.
"""

from __future__ import annotations

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

LEFT_CTRL_CODE = ecodes.KEY_LEFTCTRL
RIGHT_CTRL_CODE = ecodes.KEY_RIGHTCTRL
CTRL_CODES = {LEFT_CTRL_CODE, RIGHT_CTRL_CODE}

DOUBLE_TAP_WINDOW = 0.45
MAX_TAP_HOLD = 0.30
TRIGGER_COOLDOWN = 1.30
MIN_MODE_ON_SECONDS_BEFORE_STOP = 1.20
TAP_DEDUP_WINDOW = 0.07
RESCAN_INTERVAL = 5.0

LOCAL_DICTATION_CMD = "/home/groot/.local/bin/local-live-dictation.py"
VOICE_COMMANDS_CMD = "/home/groot/.local/bin/local-voice-commands.py"

UID = os.getuid()
XDG_RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{UID}")
DICTATION_PID_FILE = Path(XDG_RUNTIME_DIR) / "local-live-dictation" / "loop.pid"
DICTATION_TYPING_FILE = Path(XDG_RUNTIME_DIR) / "local-live-dictation" / "typing.on"
VOICE_COMMAND_PID_FILE = Path(XDG_RUNTIME_DIR) / "local-voice-commands" / "loop.pid"

ENABLE_START_SOUND = os.environ.get("LOCAL_DICT_ENABLE_START_SOUND", "0").strip().lower() not in {"0", "false", "no", "off"}
ENABLE_STOP_SOUND = os.environ.get("LOCAL_DICT_ENABLE_STOP_SOUND", "1").strip().lower() not in {"0", "false", "no", "off"}
START_SOUND_EVENT = os.environ.get("LOCAL_DICT_START_SOUND_EVENT", "bell").strip() or "bell"
STOP_SOUND_EVENT = os.environ.get("LOCAL_DICT_STOP_SOUND_EVENT", "complete").strip() or "complete"
DEFAULT_MODE = os.environ.get("LOCAL_SPEECH_DEFAULT_MODE", "commands").strip().lower()
try:
    DEFAULT_MODE_DELAY_SECONDS = max(0.0, float(os.environ.get("LOCAL_SPEECH_DEFAULT_MODE_DELAY_SECONDS", "0.8")))
except Exception:
    DEFAULT_MODE_DELAY_SECONDS = 0.8

RUNNING = True


def _handle_signal(_signum, _frame):
    global RUNNING
    RUNNING = False


def _is_keyboard_like(device: InputDevice) -> bool:
    name = (device.name or "").lower()
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
                    "ctrl_code_down": 0,
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


def _read_pid(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except Exception:
        return None


def _dictation_running() -> bool:
    pid = _read_pid(DICTATION_PID_FILE)
    return bool(pid and _pid_alive(pid))


def _typing_active() -> bool:
    return _dictation_running() and DICTATION_TYPING_FILE.exists()


def _voice_commands_running() -> bool:
    pid = _read_pid(VOICE_COMMAND_PID_FILE)
    return bool(pid and _pid_alive(pid))


def _run_mode_cmd(argv: list[str], timeout: float = 20.0) -> tuple[int, str]:
    out = ""
    rc = 1
    try:
        proc = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
            timeout=timeout,
        )
        rc = proc.returncode
        out = (proc.stdout or "").strip() or (proc.stderr or "").strip()
    except Exception as exc:
        out = str(exc)
    return rc, out


def _play_state_sound(on: bool) -> None:
    if on and not ENABLE_START_SOUND:
        return
    if (not on) and not ENABLE_STOP_SOUND:
        return
    event_id = START_SOUND_EVENT if on else STOP_SOUND_EVENT
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
    try:
        args = ["notify-send", "-a", "Speech Modes", summary]
        if body:
            args.append(body)
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def _stop_dictation_daemon_for_switch() -> None:
    if not _dictation_running():
        return
    _run_mode_cmd([LOCAL_DICTATION_CMD, "daemon-stop"], timeout=25)


def _stop_voice_commands_for_switch() -> None:
    if not _voice_commands_running():
        return
    _run_mode_cmd([VOICE_COMMANDS_CMD, "stop"], timeout=20)


def _trigger_dictation(now: float, last_dictation_on_ts: float) -> float:
    typing_active = _typing_active()

    if typing_active and last_dictation_on_ts > 0.0 and (now - last_dictation_on_ts) < MIN_MODE_ON_SECONDS_BEFORE_STOP:
        wait_left = max(0.0, MIN_MODE_ON_SECONDS_BEFORE_STOP - (now - last_dictation_on_ts))
        print(f"[double-ctrl] ignoring dictation stop while still starting ({wait_left:.1f}s)", flush=True)
        _play_state_sound(True)
        _notify("Dictation", "Still starting...")
        return last_dictation_on_ts

    action = "stop" if typing_active else "start"
    print(f"[double-ctrl] trigger -> dictation {action}", flush=True)

    if action == "start":
        _stop_voice_commands_for_switch()
        _notify("Dictation", "Starting (commands off)...")
        rc, out = _run_mode_cmd([LOCAL_DICTATION_CMD, "start"], timeout=20)
        ok = rc == 0 and out in {"started", "typing-on", "already-on", "already-running"}
        if ok:
            _play_state_sound(True)
            _notify("Dictation On", "Live transcription enabled")
            return now
        _play_state_sound(False)
        _notify("Dictation Start Failed", out or "See log")
        print(f"[double-ctrl] dictation start failed rc={rc} out={out}", flush=True)
        return last_dictation_on_ts

    rc, out = _run_mode_cmd([LOCAL_DICTATION_CMD, "stop"], timeout=15)
    ok = rc == 0 and out in {"typing-off", "already-off", "stopped", "already-stopped"}
    if ok:
        _play_state_sound(False)
        _notify("Dictation Off", "Live transcription disabled")
        return 0.0

    _play_state_sound(False)
    _notify("Dictation Stop Failed", out or "See log")
    print(f"[double-ctrl] dictation stop failed rc={rc} out={out}", flush=True)
    return last_dictation_on_ts


def _trigger_voice_commands(now: float, last_commands_on_ts: float) -> float:
    commands_running = _voice_commands_running()

    if commands_running and last_commands_on_ts > 0.0 and (now - last_commands_on_ts) < MIN_MODE_ON_SECONDS_BEFORE_STOP:
        wait_left = max(0.0, MIN_MODE_ON_SECONDS_BEFORE_STOP - (now - last_commands_on_ts))
        print(f"[double-ctrl] ignoring commands stop while still starting ({wait_left:.1f}s)", flush=True)
        _play_state_sound(True)
        _notify("Voice Commands", "Still starting...")
        return last_commands_on_ts

    action = "stop" if commands_running else "start"
    print(f"[double-ctrl] trigger -> voice-commands {action}", flush=True)

    if action == "start":
        _stop_dictation_daemon_for_switch()
        _notify("Voice Commands", "Starting (dictation off)...")
        rc, out = _run_mode_cmd([VOICE_COMMANDS_CMD, "start"], timeout=20)
        ok = rc == 0 and out in {"started", "already-running"}
        if ok:
            _play_state_sound(True)
            _notify("Voice Commands On", "Speak commands like: open terminal")
            return now
        _play_state_sound(False)
        _notify("Voice Commands Start Failed", out or "See log")
        print(f"[double-ctrl] voice-commands start failed rc={rc} out={out}", flush=True)
        return last_commands_on_ts

    rc, out = _run_mode_cmd([VOICE_COMMANDS_CMD, "stop"], timeout=15)
    ok = rc == 0 and out in {"stopped", "already-stopped"}
    if ok:
        _play_state_sound(False)
        _notify("Voice Commands Off", "Command listening disabled")
        return 0.0

    _play_state_sound(False)
    _notify("Voice Commands Stop Failed", out or "See log")
    print(f"[double-ctrl] voice-commands stop failed rc={rc} out={out}", flush=True)
    return last_commands_on_ts


def _bootstrap_default_mode() -> tuple[float, float]:
    mode = DEFAULT_MODE
    if mode in {"", "off", "none", "disabled"}:
        return 0.0, 0.0
    if mode not in {"commands", "dictation"}:
        mode = "commands"

    now = time.monotonic()
    typing_active = _typing_active()
    commands_running = _voice_commands_running()

    if typing_active:
        print("[double-ctrl] startup: dictation already active; keeping current mode", flush=True)
        return now, 0.0
    if commands_running:
        print("[double-ctrl] startup: voice commands already active", flush=True)
        return 0.0, now

    if DEFAULT_MODE_DELAY_SECONDS > 0.0:
        time.sleep(DEFAULT_MODE_DELAY_SECONDS)

    if mode == "commands":
        _stop_dictation_daemon_for_switch()
        rc, out = _run_mode_cmd([VOICE_COMMANDS_CMD, "start"], timeout=20)
        ok = rc == 0 and out in {"started", "already-running"}
        if ok:
            print("[double-ctrl] startup -> voice-commands start", flush=True)
            _notify("Voice Commands On", "Enabled by default")
            return 0.0, time.monotonic()
        print(f"[double-ctrl] startup voice-commands failed rc={rc} out={out}", flush=True)
        return 0.0, 0.0

    _stop_voice_commands_for_switch()
    rc, out = _run_mode_cmd([LOCAL_DICTATION_CMD, "start"], timeout=20)
    ok = rc == 0 and out in {"started", "typing-on", "already-on", "already-running"}
    if ok:
        print("[double-ctrl] startup -> dictation start", flush=True)
        _notify("Dictation On", "Enabled by default")
        return time.monotonic(), 0.0

    print(f"[double-ctrl] startup dictation failed rc={rc} out={out}", flush=True)
    return 0.0, 0.0


def main() -> int:
    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    devices: Dict[int, InputDevice] = {}
    key_state: Dict[int, dict] = {}
    last_scan = 0.0

    # Global tap timelines per Ctrl side (dedupes mirrored input devices).
    last_tap_up_ts = {LEFT_CTRL_CODE: 0.0, RIGHT_CTRL_CODE: 0.0}
    last_raw_tap_ts = {LEFT_CTRL_CODE: 0.0, RIGHT_CTRL_CODE: 0.0}
    last_trigger_ts = {LEFT_CTRL_CODE: 0.0, RIGHT_CTRL_CODE: 0.0}
    last_dictation_on_ts, last_commands_on_ts = _bootstrap_default_mode()

    print("[double-ctrl] started (L+L=dictation, R+R=commands)", flush=True)

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
                    "ctrl_code_down": 0,
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
                            if state.get("ctrl_code_down") != code:
                                state["saw_other_key_during_ctrl"] = True
                            continue
                        state["ctrl_is_down"] = True
                        state["ctrl_code_down"] = code
                        state["ctrl_down_ts"] = time.monotonic()
                        state["saw_other_key_during_ctrl"] = False

                    elif value == 0:
                        if not state["ctrl_is_down"] or state.get("ctrl_code_down") != code:
                            continue

                        state["ctrl_is_down"] = False
                        held = time.monotonic() - float(state["ctrl_down_ts"]) if state["ctrl_down_ts"] else 999.0
                        valid_tap = (not state["saw_other_key_during_ctrl"]) and held <= MAX_TAP_HOLD

                        if valid_tap:
                            tap_time = time.monotonic()

                            if (tap_time - last_raw_tap_ts[code]) < TAP_DEDUP_WINDOW:
                                state["ctrl_code_down"] = 0
                                state["ctrl_down_ts"] = 0.0
                                state["saw_other_key_during_ctrl"] = False
                                continue
                            last_raw_tap_ts[code] = tap_time

                            if (
                                last_tap_up_ts[code] > 0.0
                                and (tap_time - last_tap_up_ts[code]) <= DOUBLE_TAP_WINDOW
                                and (tap_time - last_trigger_ts[code]) >= TRIGGER_COOLDOWN
                            ):
                                if code == LEFT_CTRL_CODE:
                                    last_dictation_on_ts = _trigger_dictation(tap_time, last_dictation_on_ts)
                                else:
                                    last_commands_on_ts = _trigger_voice_commands(tap_time, last_commands_on_ts)
                                last_trigger_ts[code] = tap_time
                                last_tap_up_ts[code] = 0.0
                            else:
                                last_tap_up_ts[code] = tap_time
                        else:
                            last_tap_up_ts[code] = 0.0

                        state["ctrl_code_down"] = 0
                        state["ctrl_down_ts"] = 0.0
                        state["saw_other_key_during_ctrl"] = False

                else:
                    if value == 1:
                        if state["ctrl_is_down"]:
                            state["saw_other_key_during_ctrl"] = True
                            down_code = state.get("ctrl_code_down", 0)
                            if down_code in last_tap_up_ts:
                                last_tap_up_ts[down_code] = 0.0

    for fd in list(devices.keys()):
        _remove_device(fd, devices, key_state)

    print("[double-ctrl] stopped", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
