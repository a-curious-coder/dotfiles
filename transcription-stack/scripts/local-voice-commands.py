#!/home/groot/.local/share/hyprwhspr/venv/bin/python
"""Offline realtime voice-command mode (open/close apps + web search)."""

from __future__ import annotations

import json
import os
import re
import shlex
import signal
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import quote_plus

import numpy as np
import sounddevice as sd
from pywhispercpp.model import Model

try:
    from scipy.signal import resample_poly  # type: ignore
except Exception:
    resample_poly = None

WHISPER_SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SIZE = 1024

STEP_SECONDS = float(os.environ.get("LOCAL_VCMD_STEP_SECONDS", "0.45"))
WINDOW_SECONDS = float(os.environ.get("LOCAL_VCMD_WINDOW_SECONDS", "3.4"))
MAX_BUFFER_SECONDS = float(os.environ.get("LOCAL_VCMD_MAX_BUFFER_SECONDS", "8.0"))
RMS_THRESHOLD = float(os.environ.get("LOCAL_VCMD_RMS_THRESHOLD", "0.00035"))
VOICED_FRAME_MS = int(os.environ.get("LOCAL_VCMD_VOICED_FRAME_MS", "30"))
MIN_VOICED_RATIO = float(os.environ.get("LOCAL_VCMD_MIN_VOICED_RATIO", "0.05"))
SILENCE_COMMIT_SECONDS = float(os.environ.get("LOCAL_VCMD_SILENCE_COMMIT_SECONDS", "0.85"))
FINAL_PAD_SECONDS = float(os.environ.get("LOCAL_VCMD_FINAL_PAD_SECONDS", "0.80"))
MIN_FINAL_ANCHOR_WORDS = int(os.environ.get("LOCAL_VCMD_MIN_FINAL_ANCHOR_WORDS", "2"))
COMMAND_CONFIRM_REPETITIONS = int(os.environ.get("LOCAL_VCMD_COMMAND_CONFIRM_REPETITIONS", "1"))
COMMAND_COOLDOWN_SECONDS = float(os.environ.get("LOCAL_VCMD_COMMAND_COOLDOWN_SECONDS", "1.5"))
ZOOM_KEY_DELAY_MS = int(os.environ.get("LOCAL_VCMD_ZOOM_KEY_DELAY_MS", "14"))
ZOOM_STEP_SLEEP_MS = int(os.environ.get("LOCAL_VCMD_ZOOM_STEP_SLEEP_MS", "40"))
ZOOM_REPEAT_MAX = max(1, int(os.environ.get("LOCAL_VCMD_ZOOM_REPEAT_MAX", "30")))

MODEL_NAME = os.environ.get("LOCAL_VCMD_MODEL", "base.en")
LANGUAGE_OVERRIDE = os.environ.get("LOCAL_VCMD_LANGUAGE", "en")
DEBUG = os.environ.get("LOCAL_VCMD_DEBUG", "1").strip().lower() not in {"0", "false", "no", "off"}
LOG_TRANSCRIPTS = os.environ.get("LOCAL_VCMD_LOG_TRANSCRIPTS", "1").strip().lower() not in {"0", "false", "no", "off"}
PAYLOAD_SEP = "\t"

WORKSPACE_NUMBER_WORDS = {
    "zero": "0",
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
    "ten": "10",
    "first": "1",
    "second": "2",
    "third": "3",
    "fourth": "4",
    "fifth": "5",
    "sixth": "6",
    "seventh": "7",
    "eighth": "8",
    "ninth": "9",
    "tenth": "10",
}

REPEAT_NUMBER_WORDS = {
    "a": 1,
    "an": 1,
    "one": 1,
    "once": 1,
    "two": 2,
    "twice": 2,
    "three": 3,
    "thrice": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
    "fifteen": 15,
    "sixteen": 16,
    "seventeen": 17,
    "eighteen": 18,
    "nineteen": 19,
    "twenty": 20,
    "thirty": 30,
}

XDG_RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/tmp/{os.getuid()}")
STATE_DIR = Path(XDG_RUNTIME_DIR) / "local-voice-commands"
PID_FILE = STATE_DIR / "loop.pid"
STOP_FILE = STATE_DIR / "stop"
DICTATION_PID_FILE = Path(XDG_RUNTIME_DIR) / "local-live-dictation" / "loop.pid"
LOG_FILE = Path.home() / ".local" / "state" / "local-voice-commands.log"
CONFIG_FILE = Path.home() / ".config" / "local-voice-commands" / "config.json"
LOCAL_DICTATION_CMD = Path.home() / ".local" / "bin" / "local-live-dictation.py"
HYPRWHSPR_CONFIG = Path.home() / ".config" / "hyprwhspr" / "config.json"

HALLUCINATION_MARKERS = {
    "blank",
    "blank audio",
    "video playback",
    "music",
    "silence",
    "quiet",
    "inaudible",
    "foreign",
    "pause",
}

DEFAULT_CONFIG: Dict[str, Any] = {
    "apps": [
        {
            "id": "terminal",
            "aliases": ["terminal", "shell", "console"],
            "launch": "ghostty",
            "match": {
                "class_contains": [
                    "ghostty",
                    "kitty",
                    "alacritty",
                    "wezterm",
                    "foot",
                    "gnome-terminal",
                    "konsole",
                    "xterm",
                ]
            },
        },
        {
            "id": "browser",
            "aliases": ["browser", "web browser", "internet"],
            "launch": "brave",
            "match": {
                "class_contains": [
                    "firefox",
                    "chromium",
                    "google-chrome",
                    "brave-browser",
                    "microsoft-edge",
                    "vivaldi",
                ]
            },
        },
        {
            "id": "files",
            "aliases": ["files", "file manager", "explorer"],
            "launch": "thunar",
            "match": {"class_contains": ["thunar", "nautilus", "dolphin", "pcmanfm"]},
        },
        {
            "id": "obsidian",
            "aliases": ["obsidian", "notes", "vault"],
            "launch": "obsidian",
            "match": {"class_contains": ["obsidian"]},
        },
        {
            "id": "vlc",
            "aliases": ["vlc", "vlc player", "media player", "video player"],
            "launch": "vlc",
            "match": {"class_contains": ["vlc"]},
        },
        {
            "id": "discord",
            "aliases": ["discord", "chat"],
            "launch": "discord",
            "match": {"class_contains": ["discord", "vesktop"]},
        },
    ],
    "commands": [
        {
            "id": "workspace_next",
            "aliases": ["next workspace", "workspace next", "go to next workspace"],
            "dispatch": "workspace +1",
            "notify": "Next Workspace",
        },
        {
            "id": "workspace_previous",
            "aliases": ["previous workspace", "workspace previous", "go to previous workspace"],
            "dispatch": "workspace -1",
            "notify": "Previous Workspace",
        },
        {
            "id": "switch_monitor",
            "aliases": [
                "switch monitor",
                "switch to other monitor",
                "move window to other monitor",
                "send window to other monitor",
            ],
            "dispatches": ["movewindow mon:+1", "focusmonitor +1"],
            "notify": "Switch Monitor",
        },
        {
            "id": "toggle_floating",
            "aliases": ["toggle floating", "float window", "toggle floating window"],
            "dispatch": "togglefloating",
            "notify": "Toggle Floating",
        },
        {
            "id": "toggle_fullscreen",
            "aliases": ["toggle fullscreen", "fullscreen", "full screen"],
            "dispatch": "fullscreen 1",
            "notify": "Toggle Fullscreen",
        },
        {
            "id": "update_discord",
            "aliases": ["update discord", "upgrade discord", "refresh discord"],
            "exec": "~/Projects/personal/dotfiles/discord_install.sh",
            "cwd": "~/Projects/personal/dotfiles",
            "detached": True,
            "notify": "Updating Discord",
        }
    ],
    "search": {
        "default_engine": "duckduckgo",
        "engines": {
            "duckduckgo": "https://duckduckgo.com/?q={query}",
            "google": "https://www.google.com/search?q={query}",
            "bing": "https://www.bing.com/search?q={query}",
        },
    },
}

RUNNING = True


def _ensure_dirs() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)


def _ensure_config_file() -> None:
    if CONFIG_FILE.exists():
        return
    CONFIG_FILE.write_text(json.dumps(DEFAULT_CONFIG, indent=2) + "\n")


def _load_config() -> Dict[str, Any]:
    _ensure_config_file()
    try:
        cfg = json.loads(CONFIG_FILE.read_text())
    except Exception:
        return DEFAULT_CONFIG
    if not isinstance(cfg, dict):
        return DEFAULT_CONFIG
    out = dict(DEFAULT_CONFIG)

    def _merge_dict(default_dict: Any, user_dict: Any) -> Dict[str, Any]:
        base = dict(default_dict) if isinstance(default_dict, dict) else {}
        if isinstance(user_dict, dict):
            base.update(user_dict)
        return base

    def _merge_named_list(default_items: Any, user_items: Any) -> List[Dict[str, Any]]:
        defaults: List[Dict[str, Any]] = [x for x in (default_items or []) if isinstance(x, dict)]
        users: List[Dict[str, Any]] = [x for x in (user_items or []) if isinstance(x, dict)]

        user_by_id: Dict[str, Dict[str, Any]] = {}
        for item in users:
            item_id = item.get("id")
            if isinstance(item_id, str) and item_id.strip():
                user_by_id[item_id.strip()] = item

        merged: List[Dict[str, Any]] = []
        seen_ids: set[str] = set()

        for d in defaults:
            d_id = d.get("id")
            if isinstance(d_id, str) and d_id.strip() and d_id in user_by_id:
                item = dict(d)
                item.update(user_by_id[d_id])
                merged.append(item)
                seen_ids.add(d_id)
            else:
                merged.append(dict(d))
                if isinstance(d_id, str) and d_id.strip():
                    seen_ids.add(d_id)

        for u in users:
            u_id = u.get("id")
            if isinstance(u_id, str) and u_id.strip() and u_id in seen_ids:
                continue
            merged.append(dict(u))

        return merged

    for key, value in cfg.items():
        if key in {"apps", "commands", "search"}:
            continue
        out[key] = value

    out["apps"] = _merge_named_list(DEFAULT_CONFIG.get("apps"), cfg.get("apps"))
    out["commands"] = _merge_named_list(DEFAULT_CONFIG.get("commands"), cfg.get("commands"))
    out["search"] = _merge_dict(DEFAULT_CONFIG.get("search"), cfg.get("search"))

    return out


def _load_hyprwhspr_config() -> Dict[str, Any]:
    if not HYPRWHSPR_CONFIG.exists():
        return {}
    try:
        data = json.loads(HYPRWHSPR_CONFIG.read_text())
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _read_pid() -> Optional[int]:
    if not PID_FILE.exists():
        return None
    try:
        return int(PID_FILE.read_text().strip())
    except Exception:
        return None


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _is_running() -> bool:
    pid = _read_pid()
    return bool(pid and _pid_alive(pid))


def _dictation_running() -> bool:
    if not DICTATION_PID_FILE.exists():
        return False
    try:
        pid = int(DICTATION_PID_FILE.read_text().strip())
    except Exception:
        return False
    return _pid_alive(pid)


def _stop_dictation_best_effort() -> None:
    if not _dictation_running():
        return
    try:
        subprocess.run(
            [str(LOCAL_DICTATION_CMD), "daemon-stop"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=25,
        )
    except Exception:
        pass


def _remove_file(path: Path) -> None:
    try:
        path.unlink(missing_ok=True)
    except Exception:
        pass


def _stop_signal_handler(_signum, _frame):
    global RUNNING
    RUNNING = False
    try:
        STOP_FILE.touch(exist_ok=True)
    except Exception:
        pass


def _collapse_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _norm_word(word: str) -> str:
    return re.sub(r"(^\W+|\W+$)", "", word.lower())


def _common_prefix_len(a: List[str], b: List[str]) -> int:
    n = min(len(a), len(b))
    i = 0
    while i < n:
        if _norm_word(a[i]) != _norm_word(b[i]):
            break
        i += 1
    return i


def _tail_overlap_words(prev_words: List[str], new_words: List[str], limit: int = 32) -> int:
    if not prev_words or not new_words:
        return 0
    max_overlap = min(len(prev_words), len(new_words), limit)
    for k in range(max_overlap, 0, -1):
        left = [_norm_word(w) for w in prev_words[-k:]]
        right = [_norm_word(w) for w in new_words[:k]]
        if left == right:
            return k
    return 0


def _choose_final_text(pending_text: str, decoded_text: str, min_anchor_words: int) -> str:
    pending_text = _collapse_ws(pending_text)
    decoded_text = _collapse_ws(decoded_text)
    if not pending_text:
        return decoded_text
    if not decoded_text:
        return pending_text

    pending_words = pending_text.split()
    decoded_words = decoded_text.split()

    prefix = _common_prefix_len(pending_words, decoded_words)
    if prefix >= max(1, min(len(pending_words), len(decoded_words)) - 1):
        return decoded_text if len(decoded_words) >= len(pending_words) else pending_text

    overlap = _tail_overlap_words(pending_words, decoded_words, limit=64)
    if overlap >= max(1, min_anchor_words):
        return decoded_text

    return pending_text


def _is_hallucination(text: str) -> bool:
    normalized = re.sub(r"[^a-z ]", "", text.lower().replace("_", " ")).strip()
    return normalized in HALLUCINATION_MARKERS


def _notify(summary: str, body: str = "") -> None:
    try:
        args = ["notify-send", "-a", "Voice Commands", summary]
        if body:
            args.append(body)
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def _normalize_command_text(text: str) -> str:
    s = _strip_polite_prefix(text)
    s = re.sub(r"[!?.,]+$", "", s).strip()
    return _collapse_ws(s.lower())


def _normalize_device_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _pactl_default_source_name() -> str:
    try:
        proc = subprocess.run(
            ["pactl", "get-default-source"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=2,
        )
        if proc.returncode != 0:
            return ""
        return (proc.stdout or "").strip()
    except Exception:
        return ""


def _find_input_by_fuzzy_name(devices: list, wanted: str) -> Optional[Tuple[int, int, str]]:
    wanted_norm = _normalize_device_text(wanted)
    if not wanted_norm:
        return None

    def make_result(idx: int, dev: dict) -> Tuple[int, int, str]:
        rate = int(round(float(dev.get("default_samplerate", WHISPER_SAMPLE_RATE))))
        if rate <= 0:
            rate = WHISPER_SAMPLE_RATE
        return idx, rate, str(dev.get("name", f"device-{idx}"))

    for idx, dev in enumerate(devices):
        if dev.get("max_input_channels", 0) <= 0:
            continue
        dev_norm = _normalize_device_text(str(dev.get("name", "")))
        if wanted_norm in dev_norm or dev_norm in wanted_norm:
            return make_result(idx, dev)

    return None


def _pick_device() -> Tuple[Optional[int], Optional[int], str]:
    override = os.environ.get("LOCAL_VCMD_DEVICE_NAME", "").strip()
    devices = sd.query_devices()

    def make_result(idx: int, dev: dict) -> Tuple[int, int, str]:
        rate = int(round(float(dev.get("default_samplerate", WHISPER_SAMPLE_RATE))))
        if rate <= 0:
            rate = WHISPER_SAMPLE_RATE
        return idx, rate, str(dev.get("name", f"device-{idx}"))

    if override:
        hit = _find_input_by_fuzzy_name(devices, override)
        if hit:
            return hit

    source_name = _pactl_default_source_name()
    if source_name:
        hit = _find_input_by_fuzzy_name(devices, source_name)
        if hit:
            return hit

    cfg_dev = _load_hyprwhspr_config().get("audio_device_name")
    if isinstance(cfg_dev, str) and cfg_dev.strip():
        hit = _find_input_by_fuzzy_name(devices, cfg_dev.strip())
        if hit:
            return hit

    try:
        default_idx = sd.default.device
        try:
            default_idx = default_idx[0]
        except Exception:
            pass
        if default_idx is not None:
            default_idx = int(default_idx)
            dev = sd.query_devices(default_idx, kind="input")
            if dev.get("max_input_channels", 0) > 0:
                return make_result(default_idx, dev)
    except Exception:
        pass

    for idx, dev in enumerate(devices):
        if dev.get("max_input_channels", 0) > 0:
            return make_result(idx, dev)
    return None, None, ""


def _resample_to_whisper(audio: np.ndarray, source_rate: int) -> np.ndarray:
    if source_rate == WHISPER_SAMPLE_RATE:
        return audio
    if audio.size == 0:
        return audio

    if resample_poly is not None:
        try:
            out = resample_poly(audio, WHISPER_SAMPLE_RATE, source_rate).astype(np.float32, copy=False)
            return out
        except Exception:
            pass

    duration = audio.size / float(source_rate)
    target_samples = max(1, int(round(duration * WHISPER_SAMPLE_RATE)))
    x_old = np.linspace(0.0, 1.0, num=audio.size, endpoint=False)
    x_new = np.linspace(0.0, 1.0, num=target_samples, endpoint=False)
    return np.interp(x_new, x_old, audio).astype(np.float32, copy=False)


def _voiced_ratio(audio: np.ndarray, threshold: float, frame_ms: int, sample_rate: int) -> float:
    if audio.size <= 0:
        return 0.0
    frame_samples = max(1, int(sample_rate * max(5, frame_ms) / 1000.0))
    n_frames = audio.size // frame_samples
    if n_frames <= 0:
        return 1.0 if float(np.sqrt(np.mean(audio * audio))) >= threshold else 0.0
    clipped = audio[: n_frames * frame_samples]
    frames = clipped.reshape(n_frames, frame_samples)
    frame_rms = np.sqrt(np.mean(frames * frames, axis=1))
    voiced = np.count_nonzero(frame_rms >= threshold)
    return float(voiced) / float(n_frames)


@dataclass
class AudioRingBuffer:
    capacity: int
    _buffer: np.ndarray = field(init=False, repr=False)
    _size: int = field(default=0, init=False, repr=False)
    _write_pos: int = field(default=0, init=False, repr=False)
    _lock: threading.Lock = field(default_factory=threading.Lock, init=False, repr=False)

    def __post_init__(self) -> None:
        self.capacity = max(1, int(self.capacity))
        self._buffer = np.zeros(self.capacity, dtype=np.float32)

    def append(self, chunk: np.ndarray) -> None:
        data = np.asarray(chunk, dtype=np.float32).reshape(-1)
        if data.size <= 0:
            return
        with self._lock:
            if data.size >= self.capacity:
                self._buffer[:] = data[-self.capacity :]
                self._size = self.capacity
                self._write_pos = 0
                return

            first = min(self.capacity - self._write_pos, data.size)
            self._buffer[self._write_pos : self._write_pos + first] = data[:first]
            remaining = data.size - first
            if remaining > 0:
                self._buffer[:remaining] = data[first:]
            self._write_pos = (self._write_pos + data.size) % self.capacity
            self._size = min(self.capacity, self._size + data.size)

    def snapshot(self, limit_samples: Optional[int] = None) -> np.ndarray:
        with self._lock:
            if self._size <= 0:
                return np.empty(0, dtype=np.float32)
            n = self._size if limit_samples is None else max(0, min(self._size, int(limit_samples)))
            if n <= 0:
                return np.empty(0, dtype=np.float32)
            start = (self._write_pos - n) % self.capacity
            if start + n <= self.capacity:
                return self._buffer[start : start + n].copy()
            first = self.capacity - start
            return np.concatenate((self._buffer[start:], self._buffer[: n - first]), axis=0).astype(np.float32, copy=False)

    def clear(self) -> None:
        with self._lock:
            self._size = 0
            self._write_pos = 0


def _run_hypr_exec(command_text: str) -> bool:
    try:
        proc = subprocess.run(
            ["hyprctl", "dispatch", "exec", command_text],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
            timeout=8,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _run_hypr_dispatch(dispatch_text: str) -> bool:
    try:
        parts = shlex.split(dispatch_text)
        if not parts:
            return False
        proc = subprocess.run(
            ["hyprctl", "dispatch", *parts],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
            timeout=8,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _run_ydotool_key_events(key_events: List[str], key_delay_ms: int) -> bool:
    if not key_events:
        return False
    try:
        proc = subprocess.run(
            ["ydotool", "key", "--key-delay", str(key_delay_ms), *key_events],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=20,
            text=True,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _extract_repeat_factors(text: str) -> List[int]:
    tokens = re.findall(r"[a-z0-9]+", text.lower())
    factors: List[int] = []
    i = 0
    while i < len(tokens):
        tok = tokens[i]

        if tok.isdigit():
            value = int(tok)
            if value > 0:
                factors.append(value)
            i += 1
            continue

        if tok in {"x", "times", "time", "by"}:
            i += 1
            continue

        if tok in {"twenty", "thirty"}:
            value = REPEAT_NUMBER_WORDS[tok]
            if i + 1 < len(tokens):
                nxt = tokens[i + 1]
                nxt_val = REPEAT_NUMBER_WORDS.get(nxt)
                if nxt_val is not None and 1 <= nxt_val <= 9:
                    value += nxt_val
                    i += 1
            factors.append(value)
            i += 1
            continue

        value = REPEAT_NUMBER_WORDS.get(tok)
        if value is not None and value > 0:
            factors.append(value)

        i += 1

    return factors


def _parse_repeat_count(text: str, default_value: int = 1) -> int:
    factors = _extract_repeat_factors(text)
    if not factors:
        return max(1, min(default_value, ZOOM_REPEAT_MAX))

    total = 1
    for factor in factors:
        total *= max(1, factor)
        if total >= ZOOM_REPEAT_MAX:
            return ZOOM_REPEAT_MAX

    return max(1, min(total, ZOOM_REPEAT_MAX))


def _zoom_focused_window(steps: int, zoom_in: bool) -> bool:
    steps = max(1, min(int(steps), ZOOM_REPEAT_MAX))
    key_code = "13" if zoom_in else "12"  # KEY_EQUAL / KEY_MINUS

    step_events = ["29:1", f"{key_code}:1", f"{key_code}:0", "29:0"]  # Ctrl + (=|-)
    for idx in range(steps):
        if not _run_ydotool_key_events(step_events, key_delay_ms=ZOOM_KEY_DELAY_MS):
            return False
        if idx + 1 < steps and ZOOM_STEP_SLEEP_MS > 0:
            time.sleep(ZOOM_STEP_SLEEP_MS / 1000.0)
    return True


def _normalize_target(text: str) -> str:
    s = _collapse_ws(text.lower())
    s = re.sub(r"^(the|a|an)\s+", "", s)
    s = re.sub(r"\s+(please|now)$", "", s)
    return s.strip()


def _app_aliases(app: Dict[str, Any]) -> List[str]:
    aliases = []
    app_id = app.get("id")
    if isinstance(app_id, str) and app_id.strip():
        aliases.append(_normalize_target(app_id))
    raw_aliases = app.get("aliases", [])
    if isinstance(raw_aliases, list):
        for item in raw_aliases:
            if isinstance(item, str) and item.strip():
                aliases.append(_normalize_target(item))
    return list(dict.fromkeys(aliases))


def _resolve_app(cfg: Dict[str, Any], target: str) -> Optional[Dict[str, Any]]:
    target = _normalize_target(target)
    apps = cfg.get("apps", [])
    if not isinstance(apps, list):
        return None

    # Exact alias match first.
    for app in apps:
        if not isinstance(app, dict):
            continue
        aliases = _app_aliases(app)
        if target in aliases:
            return app

    # Substring fallback for natural speech variants.
    for app in apps:
        if not isinstance(app, dict):
            continue
        aliases = _app_aliases(app)
        for alias in aliases:
            if target == alias or target in alias or alias in target:
                return app
    return None


def _custom_aliases(entry: Dict[str, Any]) -> List[str]:
    aliases: List[str] = []
    entry_id = entry.get("id")
    if isinstance(entry_id, str) and entry_id.strip():
        aliases.append(_normalize_command_text(entry_id))
    raw_aliases = entry.get("aliases", [])
    if isinstance(raw_aliases, list):
        for item in raw_aliases:
            if isinstance(item, str) and item.strip():
                aliases.append(_normalize_command_text(item))
    return list(dict.fromkeys([a for a in aliases if a]))


def _resolve_custom_command(cfg: Dict[str, Any], normalized_text: str) -> Optional[Dict[str, Any]]:
    commands = cfg.get("commands", [])
    if not isinstance(commands, list):
        return None

    run_prefixes = ("run ", "execute ", "start ")
    candidate_texts = [normalized_text]
    for prefix in run_prefixes:
        if normalized_text.startswith(prefix):
            candidate_texts.append(normalized_text[len(prefix) :].strip())

    for candidate in candidate_texts:
        if not candidate:
            continue
        for entry in commands:
            if not isinstance(entry, dict):
                continue
            if candidate in _custom_aliases(entry):
                return entry
    return None


def _expand_path(text: str) -> str:
    return str(Path(text).expanduser())


def _load_hypr_clients() -> List[Dict[str, Any]]:
    try:
        proc = subprocess.run(
            ["hyprctl", "clients", "-j"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            return []
        data = json.loads(proc.stdout or "[]")
        if isinstance(data, list):
            return [x for x in data if isinstance(x, dict)]
        return []
    except Exception:
        return []


def _active_window_address() -> str:
    try:
        proc = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            return ""
        data = json.loads(proc.stdout or "{}")
        if isinstance(data, dict):
            address = str(data.get("address", "")).strip()
            return address
        return ""
    except Exception:
        return ""


def _active_workspace_name() -> str:
    try:
        proc = subprocess.run(
            ["hyprctl", "activeworkspace", "-j"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            return ""
        data = json.loads(proc.stdout or "{}")
        if isinstance(data, dict):
            return str(data.get("name", "")).strip()
        return ""
    except Exception:
        return ""


def _client_workspace_name(client: Dict[str, Any]) -> str:
    workspace = client.get("workspace")
    if isinstance(workspace, dict):
        return str(workspace.get("name", "")).strip()
    return str(workspace or "").strip()


def _encode_pair_payload(left: str, right: str) -> str:
    return f"{left}{PAYLOAD_SEP}{right}"


def _decode_pair_payload(payload: str) -> Tuple[str, str]:
    if PAYLOAD_SEP not in payload:
        return "", ""
    left, right = payload.split(PAYLOAD_SEP, 1)
    return left.strip(), right.strip()


def _normalize_workspace_target(text: str) -> str:
    s = _collapse_ws(text.lower())
    s = re.sub(r"^(?:workspace|desktop)\s+", "", s)
    s = re.sub(r"^(?:number|num)\s+", "", s)
    s = re.sub(r"\s+(?:please|now)$", "", s).strip()
    if s in WORKSPACE_NUMBER_WORDS:
        return WORKSPACE_NUMBER_WORDS[s]
    if re.fullmatch(r"[a-z0-9:+_-]+", s):
        return s
    return ""


def _close_window_by_address(address: str) -> bool:
    if not address:
        return False
    try:
        proc = subprocess.run(
            ["hyprctl", "dispatch", "closewindow", f"address:{address}"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=5,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _focus_window_by_address(address: str) -> bool:
    if not address:
        return False
    try:
        proc = subprocess.run(
            ["hyprctl", "dispatch", "focuswindow", f"address:{address}"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=5,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _close_active_window() -> bool:
    try:
        proc = subprocess.run(
            ["hyprctl", "dispatch", "killactive"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=5,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _move_window_to_workspace(address: str, workspace_target: str, *, silent: bool = False) -> bool:
    address = str(address or "").strip()
    workspace_target = str(workspace_target or "").strip()
    if not address or not workspace_target:
        return False
    dispatcher = "movetoworkspacesilent" if silent else "movetoworkspace"
    return _run_hypr_dispatch(f"{dispatcher} {workspace_target},address:{address}")


def _move_active_window_to_workspace(workspace_target: str, *, silent: bool = False) -> bool:
    address = _active_window_address()
    if not address:
        return False
    return _move_window_to_workspace(address, workspace_target, silent=silent)


def _match_client_for_app(client: Dict[str, Any], app: Dict[str, Any]) -> bool:
    match = app.get("match", {})
    if not isinstance(match, dict):
        return False
    cls = str(client.get("class", "")).lower()
    title = str(client.get("title", "")).lower()

    class_contains = match.get("class_contains", [])
    if isinstance(class_contains, list):
        for token in class_contains:
            if isinstance(token, str) and token.lower() in cls:
                return True

    title_contains = match.get("title_contains", [])
    if isinstance(title_contains, list):
        for token in title_contains:
            if isinstance(token, str) and token.lower() in title:
                return True
    return False


def _matching_clients_for_app(app: Dict[str, Any]) -> List[Dict[str, Any]]:
    clients = _load_hypr_clients()
    return [client for client in clients if _match_client_for_app(client, app)]


def _select_preferred_client(clients: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    if not clients:
        return None

    active_workspace = _active_workspace_name()
    if active_workspace:
        for client in clients:
            if _client_workspace_name(client) == active_workspace:
                return client

    return clients[0]


def _open_app(app: Dict[str, Any]) -> bool:
    launch = app.get("launch", "")
    if not isinstance(launch, str) or not launch.strip():
        return False
    launch_cmd = launch.strip()
    try:
        subprocess.Popen(
            ["bash", "-lc", launch_cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        return True
    except Exception:
        return _run_hypr_exec(launch_cmd)


def _show_app(app: Dict[str, Any]) -> bool:
    client = _select_preferred_client(_matching_clients_for_app(app))
    if client is not None:
        if _focus_window_by_address(str(client.get("address", ""))):
            return True
    return _open_app(app)


def _focus_app(app: Dict[str, Any]) -> bool:
    client = _select_preferred_client(_matching_clients_for_app(app))
    if client is None:
        return False
    return _focus_window_by_address(str(client.get("address", "")))


def _move_app_to_workspace(app: Dict[str, Any], workspace_target: str, *, silent: bool = False) -> bool:
    client = _select_preferred_client(_matching_clients_for_app(app))
    if client is None:
        return False
    return _move_window_to_workspace(str(client.get("address", "")), workspace_target, silent=silent)


def _close_app(app: Dict[str, Any]) -> bool:
    clients = _load_hypr_clients()
    for client in clients:
        if _match_client_for_app(client, app):
            if _close_window_by_address(str(client.get("address", ""))):
                return True

    close_cmd = app.get("close", "")
    if isinstance(close_cmd, str) and close_cmd.strip():
        return _run_hypr_exec(close_cmd.strip())
    return False


def _search_web(cfg: Dict[str, Any], query: str) -> bool:
    query = _collapse_ws(query)
    if not query:
        return False

    search_cfg = cfg.get("search", {})
    if not isinstance(search_cfg, dict):
        search_cfg = DEFAULT_CONFIG.get("search", {})

    engines = search_cfg.get("engines", {})
    if not isinstance(engines, dict):
        engines = {}

    default_engine = str(search_cfg.get("default_engine", "duckduckgo")).strip() or "duckduckgo"
    template = engines.get(default_engine) or DEFAULT_CONFIG["search"]["engines"]["duckduckgo"]
    if not isinstance(template, str) or "{query}" not in template:
        template = DEFAULT_CONFIG["search"]["engines"]["duckduckgo"]

    url = template.format(query=quote_plus(query))
    try:
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return _run_hypr_exec(f"xdg-open {shlex.quote(url)}")


def _execute_custom_command(entry: Dict[str, Any]) -> bool:
    dispatches_cmd = entry.get("dispatches", [])
    if isinstance(dispatches_cmd, list):
        commands = [str(x).strip() for x in dispatches_cmd if isinstance(x, str) and str(x).strip()]
        if commands:
            for dispatch_text in commands:
                if not _run_hypr_dispatch(dispatch_text):
                    return False
            return True

    dispatch_cmd = entry.get("dispatch", "")
    if isinstance(dispatch_cmd, str) and dispatch_cmd.strip():
        return _run_hypr_dispatch(dispatch_cmd.strip())

    exec_cmd = entry.get("exec", "")
    if not isinstance(exec_cmd, str) or not exec_cmd.strip():
        return False

    cwd_raw = entry.get("cwd", "")
    cwd = _expand_path(cwd_raw) if isinstance(cwd_raw, str) and cwd_raw.strip() else None
    detached = bool(entry.get("detached", True))

    if detached:
        try:
            subprocess.Popen(
                ["bash", "-lc", exec_cmd],
                cwd=cwd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            return True
        except Exception:
            return False

    try:
        proc = subprocess.run(
            ["bash", "-lc", exec_cmd],
            cwd=cwd,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=600,
            text=True,
        )
        return proc.returncode == 0
    except Exception:
        return False


def _strip_polite_prefix(text: str) -> str:
    text = _collapse_ws(text.lower())
    prefixes = (
        "please ",
        "can you ",
        "could you ",
        "would you ",
        "i want to ",
        "i'd like to ",
    )
    changed = True
    while changed:
        changed = False
        for prefix in prefixes:
            if text.startswith(prefix):
                text = text[len(prefix) :]
                changed = True
    return text.strip()


def _parse_intent(text: str) -> Tuple[str, str]:
    s = _normalize_command_text(text)
    if not s:
        return "", ""

    if re.match(r"^(?:close|quit|exit|stop|kill)(?:\s+(?:current|this|active))?(?:\s+(?:app|application|window))?$", s):
        return "close-active", "active-window"

    for pattern in (
        r"^(?:search(?: web)?(?: for)?|find|look up|google)\s+(.+)$",
        r"^open (?:the )?(?:browser|web|internet)(?: and)? search(?: for)?\s+(.+)$",
    ):
        m = re.match(pattern, s)
        if m:
            return "search", _collapse_ws(m.group(1))

    m = re.match(r"^(?:enhance|zoom in|increase zoom)(?:\s+(.+))?$", s)
    if m:
        count = _parse_repeat_count(m.group(1) or "", default_value=1)
        return "zoom-in", str(count)

    m = re.match(r"^(?:zoom out|decrease zoom|reduce zoom|shrink)(?:\s+(.+))?$", s)
    if m:
        count = _parse_repeat_count(m.group(1) or "", default_value=1)
        return "zoom-out", str(count)

    m = re.match(r"^(?:open|launch|start|run)\s+(.+)$", s)
    if m:
        return "open", _normalize_target(m.group(1))

    m = re.match(r"^(?:focus|activate)(?:\s+on)?\s+(.+)$", s)
    if m:
        return "focus", _normalize_target(m.group(1))

    m = re.match(r"^(?:show|bring|raise|switch to)\s+(.+)$", s)
    if m:
        return "show", _normalize_target(m.group(1))

    m = re.match(r"^(?:move|send)\s+(.+?)\s+to\s+(?:workspace|desktop)\s+(.+)$", s)
    if m:
        app_target = _normalize_target(m.group(1))
        workspace_target = _normalize_workspace_target(m.group(2))
        if not workspace_target:
            return "", ""
        active_targets = {
            "window",
            "current window",
            "active window",
            "this window",
            "current",
            "active",
            "this",
            "app",
            "application",
            "current app",
            "active app",
            "this app",
        }
        if app_target in active_targets:
            return "move-active-workspace", workspace_target
        return "move-app-workspace", _encode_pair_payload(app_target, workspace_target)

    m = re.match(r"^(?:close|quit|exit|stop|kill)\s+(.+)$", s)
    if m:
        target = _normalize_target(m.group(1))
        if target in {"app", "application", "window", "this", "current", "current window", "active window"}:
            return "close-active", target
        return "close", target

    return "", ""


def _intent_key(intent: str, payload: str) -> str:
    return f"{intent}:{_collapse_ws(payload).lower()}"


def _execute_intent(intent: str, payload: str, cfg: Dict[str, Any]) -> bool:
    if intent == "search":
        ok = _search_web(cfg, payload)
        if DEBUG:
            print(f"[voice-cmd] command search payload={payload!r} ok={ok}", flush=True)
        _notify("Search", payload if ok else f"failed: {payload}")
        return ok

    if intent == "zoom-in":
        count = _parse_repeat_count(payload, default_value=1)
        ok = _zoom_focused_window(count, zoom_in=True)
        if DEBUG:
            print(f"[voice-cmd] command zoom-in count={count} ok={ok}", flush=True)
        _notify("Enhance", f"x{count}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "zoom-out":
        count = _parse_repeat_count(payload, default_value=1)
        ok = _zoom_focused_window(count, zoom_in=False)
        if DEBUG:
            print(f"[voice-cmd] command zoom-out count={count} ok={ok}", flush=True)
        _notify("Zoom Out", f"x{count}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "close-active":
        ok = _close_active_window()
        if DEBUG:
            print(f"[voice-cmd] command close-active ok={ok}", flush=True)
        _notify("Close Active Window", "ok" if ok else "failed")
        return ok

    if intent == "move-active-workspace":
        ok = _move_active_window_to_workspace(payload, silent=True)
        if DEBUG:
            print(f"[voice-cmd] command move-active-workspace workspace={payload!r} ok={ok}", flush=True)
        _notify("Move Active Window", f"workspace {payload}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "move-app-workspace":
        app_target, workspace_target = _decode_pair_payload(payload)
        if not app_target or not workspace_target:
            if DEBUG:
                print(f"[voice-cmd] bad move-app-workspace payload={payload!r}", flush=True)
            _notify("Move App", "invalid command payload")
            return False
        app = _resolve_app(cfg, app_target)
        if app is None:
            _notify("Unknown app", app_target)
            if DEBUG:
                print(f"[voice-cmd] unknown-app: {app_target}", flush=True)
            return False
        app_id = str(app.get("id", app_target))
        ok = _move_app_to_workspace(app, workspace_target, silent=True)
        if DEBUG:
            print(
                f"[voice-cmd] command move-app-workspace app={app_id!r} workspace={workspace_target!r} ok={ok}",
                flush=True,
            )
        _notify("Move App", f"{app_id} -> workspace {workspace_target}: {'ok' if ok else 'failed'}")
        return ok

    app = _resolve_app(cfg, payload)
    if app is None:
        _notify("Unknown app", payload)
        if DEBUG:
            print(f"[voice-cmd] unknown-app: {payload}", flush=True)
        return False

    app_id = str(app.get("id", payload))
    if intent == "open":
        ok = _open_app(app)
        if DEBUG:
            print(f"[voice-cmd] command open app={app_id!r} ok={ok}", flush=True)
        _notify("Open App", f"{app_id}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "show":
        ok = _show_app(app)
        if DEBUG:
            print(f"[voice-cmd] command show app={app_id!r} ok={ok}", flush=True)
        _notify("Show App", f"{app_id}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "focus":
        ok = _focus_app(app)
        if DEBUG:
            print(f"[voice-cmd] command focus app={app_id!r} ok={ok}", flush=True)
        _notify("Focus App", f"{app_id}: {'ok' if ok else 'failed'}")
        return ok

    if intent == "close":
        ok = _close_app(app)
        if DEBUG:
            print(f"[voice-cmd] command close app={app_id!r} ok={ok}", flush=True)
        _notify("Close App", f"{app_id}: {'ok' if ok else 'failed'}")
        return ok

    return False


def _execute_command(text: str, cfg: Dict[str, Any]) -> bool:
    normalized = _normalize_command_text(text)
    custom = _resolve_custom_command(cfg, normalized)
    if custom is not None:
        ok = _execute_custom_command(custom)
        custom_id = str(custom.get("id", "custom"))
        custom_notify = str(custom.get("notify", custom_id))
        if DEBUG:
            print(f"[voice-cmd] command custom id={custom_id!r} ok={ok}", flush=True)
        _notify("Run Command", f"{custom_notify}: {'ok' if ok else 'failed'}")
        return ok

    intent, payload = _parse_intent(text)
    if not intent or not payload:
        if DEBUG:
            print(f"[voice-cmd] ignored: {text}", flush=True)
        _notify("No command recognized", text)
        return False
    return _execute_intent(intent, payload, cfg)


def _run_loop() -> int:
    _ensure_dirs()

    if _is_running() and _read_pid() != os.getpid():
        return 0

    PID_FILE.write_text(str(os.getpid()))
    _remove_file(STOP_FILE)

    signal.signal(signal.SIGINT, _stop_signal_handler)
    signal.signal(signal.SIGTERM, _stop_signal_handler)

    cfg = _load_config()

    try:
        print(f"[voice-cmd] loading model={MODEL_NAME}", flush=True)
        model = Model(
            MODEL_NAME,
            print_realtime=False,
            print_progress=False,
            print_timestamps=False,
            single_segment=False,
            no_context=True,
        )
    except Exception as exc:
        print(f"[voice-cmd] failed to load model: {exc}", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        return 1

    device_id, capture_rate, device_name = _pick_device()
    if device_id is None or capture_rate is None:
        print("[voice-cmd] no input device found", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        return 1

    print(f"[voice-cmd] using input device: {device_name} (id={device_id}, rate={capture_rate}Hz)", flush=True)

    max_samples = int(MAX_BUFFER_SECONDS * capture_rate)
    window_samples = int(WINDOW_SECONDS * capture_rate)
    audio_buffer = AudioRingBuffer(max_samples)

    last_process = 0.0
    phrase_text = ""
    phrase_started_ts = 0.0
    last_voice_ts = 0.0
    candidate_key = ""
    candidate_repetitions = 0
    last_execute_ts = 0.0

    def _current_language() -> str:
        lang = LANGUAGE_OVERRIDE.strip()
        if lang:
            return lang
        return "en"

    def _transcribe_window(audio_window: np.ndarray, pad_seconds: float = 0.0) -> str:
        if audio_window.size <= 0:
            return ""
        if pad_seconds > 0.0:
            pad_samples = max(1, int(round(pad_seconds * capture_rate)))
            audio_window = np.concatenate([audio_window, np.zeros(pad_samples, dtype=np.float32)], axis=0)

        whisper_audio = _resample_to_whisper(audio_window, capture_rate)
        if whisper_audio.size <= 0:
            return ""

        try:
            kwargs = {}
            lang = _current_language()
            if lang:
                kwargs["language"] = lang
            segments = model.transcribe(whisper_audio, n_processors=None, **kwargs)
            text = " ".join(seg.text for seg in segments if getattr(seg, "text", "")).strip()
        except Exception:
            return ""

        text = _collapse_ws(text)
        if not text or _is_hallucination(text):
            return ""
        return text

    def _finalize_phrase() -> None:
        nonlocal phrase_text, phrase_started_ts, last_voice_ts, candidate_key, candidate_repetitions

        pending = _collapse_ws(phrase_text)
        if not pending:
            return

        audio_now = audio_buffer.snapshot(limit_samples=window_samples)
        decoded = _transcribe_window(audio_now, pad_seconds=FINAL_PAD_SECONDS) if audio_now.size > 0 else ""
        final_text = _choose_final_text(pending, decoded, MIN_FINAL_ANCHOR_WORDS)

        if DEBUG and LOG_TRANSCRIPTS:
            print(f"[voice-cmd] finalize: {final_text}", flush=True)

        _execute_command(final_text, cfg)

        phrase_text = ""
        phrase_started_ts = 0.0
        last_voice_ts = 0.0
        candidate_key = ""
        candidate_repetitions = 0
        audio_buffer.clear()

    def _try_execute_live_command(text: str, now: float) -> bool:
        nonlocal phrase_text, phrase_started_ts, last_voice_ts, candidate_key, candidate_repetitions, last_execute_ts

        normalized = _normalize_command_text(text)
        custom = _resolve_custom_command(cfg, normalized)
        if custom is not None:
            custom_id = str(custom.get("id", "custom"))
            key = f"custom:{custom_id}"

            if key == candidate_key:
                candidate_repetitions += 1
            else:
                candidate_key = key
                candidate_repetitions = 1

            if candidate_repetitions < max(1, COMMAND_CONFIRM_REPETITIONS):
                return False
            if (now - last_execute_ts) < max(0.0, COMMAND_COOLDOWN_SECONDS):
                return False

            ok = _execute_custom_command(custom)
            custom_notify = str(custom.get("notify", custom_id))
            if DEBUG:
                print(f"[voice-cmd] command custom id={custom_id!r} ok={ok}", flush=True)
            _notify("Run Command", f"{custom_notify}: {'ok' if ok else 'failed'}")
            last_execute_ts = now
            candidate_key = ""
            candidate_repetitions = 0
            phrase_text = ""
            phrase_started_ts = 0.0
            last_voice_ts = 0.0
            audio_buffer.clear()
            return ok

        intent, payload = _parse_intent(text)
        if not intent or not payload:
            candidate_key = ""
            candidate_repetitions = 0
            return False

        key = _intent_key(intent, payload)
        if key == candidate_key:
            candidate_repetitions += 1
        else:
            candidate_key = key
            candidate_repetitions = 1

        if candidate_repetitions < max(1, COMMAND_CONFIRM_REPETITIONS):
            return False
        if (now - last_execute_ts) < max(0.0, COMMAND_COOLDOWN_SECONDS):
            return False

        ok = _execute_intent(intent, payload, cfg)
        last_execute_ts = now
        candidate_key = ""
        candidate_repetitions = 0
        phrase_text = ""
        phrase_started_ts = 0.0
        last_voice_ts = 0.0
        audio_buffer.clear()
        return ok

    def audio_callback(indata, _frames, _time_info, status):
        if status:
            return
        mono = indata[:, 0].copy()
        audio_buffer.append(mono)

    print("[voice-cmd] started", flush=True)
    if DEBUG:
        print(
            "[voice-cmd] settings "
            f"step={STEP_SECONDS}s window={WINDOW_SECONDS}s max_buffer={MAX_BUFFER_SECONDS}s "
            f"rms_threshold={RMS_THRESHOLD} min_voiced_ratio={MIN_VOICED_RATIO} "
            f"silence_commit={SILENCE_COMMIT_SECONDS}s final_pad={FINAL_PAD_SECONDS}s "
            f"confirm_repetitions={COMMAND_CONFIRM_REPETITIONS} cooldown={COMMAND_COOLDOWN_SECONDS}s",
            flush=True,
        )

    try:
        with sd.InputStream(
            device=device_id,
            samplerate=capture_rate,
            channels=CHANNELS,
            dtype=np.float32,
            blocksize=BLOCK_SIZE,
            callback=audio_callback,
        ):
            while RUNNING and not STOP_FILE.exists():
                now = time.monotonic()
                if now - last_process < STEP_SECONDS:
                    time.sleep(0.03)
                    continue
                last_process = now

                audio = audio_buffer.snapshot(limit_samples=window_samples)
                if audio.size <= 0:
                    continue

                rms = float(np.sqrt(np.mean(audio * audio)))
                voiced_ratio = _voiced_ratio(audio, RMS_THRESHOLD, VOICED_FRAME_MS, capture_rate)
                is_voiced = rms >= RMS_THRESHOLD and voiced_ratio >= MIN_VOICED_RATIO

                if is_voiced:
                    text = _transcribe_window(audio)
                    if text:
                        phrase_text = text
                        if phrase_started_ts <= 0.0:
                            phrase_started_ts = now
                        last_voice_ts = now
                        if DEBUG and LOG_TRANSCRIPTS:
                            preview = text if len(text) <= 140 else text[:137] + "..."
                            print(f"[voice-cmd] heard: {preview}", flush=True)
                        _try_execute_live_command(text, now)
                    continue

                if phrase_text and last_voice_ts > 0.0 and (now - last_voice_ts) >= SILENCE_COMMIT_SECONDS:
                    _finalize_phrase()

            if phrase_text:
                _finalize_phrase()

    finally:
        print("[voice-cmd] stopped", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)

    return 0


def _daemon_start() -> int:
    _ensure_dirs()
    _stop_dictation_best_effort()
    if _is_running():
        print("already-running")
        return 0

    _remove_file(STOP_FILE)

    with LOG_FILE.open("a", buffering=1) as log:
        proc = subprocess.Popen(
            [str(Path(__file__).resolve()), "run"],
            stdout=log,
            stderr=subprocess.STDOUT,
            start_new_session=True,
        )

    for _ in range(60):
        if _is_running():
            print("started")
            return 0
        time.sleep(0.05)

    if proc.poll() is None:
        print("started")
        return 0

    print("start-failed")
    return 1


def _daemon_stop() -> int:
    _ensure_dirs()
    pid = _read_pid()
    if not pid or not _pid_alive(pid):
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        print("already-stopped")
        return 0

    STOP_FILE.touch(exist_ok=True)
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError:
        pass

    for _ in range(80):
        if not _pid_alive(pid):
            break
        time.sleep(0.05)

    if _pid_alive(pid):
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass

    _remove_file(PID_FILE)
    _remove_file(STOP_FILE)
    print("stopped")
    return 0


def _status() -> int:
    running = _is_running()
    print(f"running={1 if running else 0}")
    return 0


def _simulate(text: str) -> int:
    phrase = _collapse_ws(text)
    if not phrase:
        print("simulate-empty")
        return 2
    cfg = _load_config()
    print(f"simulate: {phrase}")
    _execute_command(phrase, cfg)
    return 0


def main() -> int:
    cmd = (sys.argv[1] if len(sys.argv) > 1 else "toggle").lower()
    if cmd == "run":
        return _run_loop()
    if cmd in {"start", "daemon-start"}:
        return _daemon_start()
    if cmd in {"stop", "daemon-stop"}:
        return _daemon_stop()
    if cmd == "status":
        return _status()
    if cmd == "simulate":
        return _simulate(" ".join(sys.argv[2:]))
    if cmd == "toggle":
        return _daemon_stop() if _is_running() else _daemon_start()

    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
