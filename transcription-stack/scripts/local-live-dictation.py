#!/home/groot/.local/share/hyprwhspr/venv/bin/python
"""Offline near-realtime dictation using local Whisper (no API keys)."""

from __future__ import annotations

import json
import os
import re
import signal
import subprocess
import sys
import threading
import time
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Deque, List, Optional, Tuple

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

STEP_SECONDS = float(os.environ.get("LOCAL_DICT_STEP_SECONDS", "0.5"))
WINDOW_SECONDS = float(os.environ.get("LOCAL_DICT_WINDOW_SECONDS", "3.6"))
MAX_BUFFER_SECONDS = float(os.environ.get("LOCAL_DICT_MAX_BUFFER_SECONDS", "8.0"))
RMS_THRESHOLD = float(os.environ.get("LOCAL_DICT_RMS_THRESHOLD", "0.00035"))
KEY_DELAY_MS = int(os.environ.get("LOCAL_DICT_KEY_DELAY_MS", "2"))
PUNCTUATION_STYLE = os.environ.get("LOCAL_DICT_PUNCTUATION_STYLE", "adaptive").strip().lower()
SHORT_SENTENCE_TERMINAL_WORDS = int(os.environ.get("LOCAL_DICT_SHORT_SENTENCE_TERMINAL_WORDS", "6"))

MODEL_NAME = os.environ.get("LOCAL_DICT_MODEL", "base.en")
LANGUAGE_OVERRIDE = os.environ.get("LOCAL_DICT_LANGUAGE", "en")
DEBUG = os.environ.get("LOCAL_DICT_DEBUG", "1").strip().lower() not in {"0", "false", "no", "off"}
LOG_TRANSCRIPTS = os.environ.get("LOCAL_DICT_LOG_TRANSCRIPTS", "1").strip().lower() not in {"0", "false", "no", "off"}
STABLE_PREFIX_GUARD_WORDS = int(os.environ.get("LOCAL_DICT_STABLE_PREFIX_GUARD_WORDS", "0"))
EMIT_HISTORY_WORDS = int(os.environ.get("LOCAL_DICT_EMIT_HISTORY_WORDS", "72"))
SILENCE_RESET_SECONDS = float(os.environ.get("LOCAL_DICT_SILENCE_RESET_SECONDS", "1.2"))
AUTO_STOP_SILENCE_SECONDS = float(os.environ.get("LOCAL_DICT_AUTO_STOP_SILENCE_SECONDS", "12.0"))
MIN_EMIT_WORDS = int(os.environ.get("LOCAL_DICT_MIN_EMIT_WORDS", "1"))
TAIL_REVISION_MAX_WORDS = int(os.environ.get("LOCAL_DICT_TAIL_REVISION_MAX_WORDS", "6"))
TAIL_REVISION_MIN_ANCHOR_WORDS = int(os.environ.get("LOCAL_DICT_TAIL_REVISION_MIN_ANCHOR_WORDS", "3"))
FLUSH_MIN_ANCHOR_WORDS = int(os.environ.get("LOCAL_DICT_FLUSH_MIN_ANCHOR_WORDS", "2"))
SILENCE_FLUSH_GUARD_WORDS = int(os.environ.get("LOCAL_DICT_SILENCE_FLUSH_GUARD_WORDS", "0"))
EXIT_FLUSH_GUARD_WORDS = int(os.environ.get("LOCAL_DICT_EXIT_FLUSH_GUARD_WORDS", "0"))
EXIT_FLUSH_MAX_IDLE_SECONDS = float(os.environ.get("LOCAL_DICT_EXIT_FLUSH_MAX_IDLE_SECONDS", "2.5"))
FINAL_FLUSH_PAD_SECONDS = float(os.environ.get("LOCAL_DICT_FINAL_FLUSH_PAD_SECONDS", "0.70"))
VOICED_FRAME_MS = int(os.environ.get("LOCAL_DICT_VOICED_FRAME_MS", "30"))
MIN_VOICED_RATIO = float(os.environ.get("LOCAL_DICT_MIN_VOICED_RATIO", "0.05"))
VOICE_CONTINUATION_SECONDS = float(os.environ.get("LOCAL_DICT_VOICE_CONTINUATION_SECONDS", "1.8"))
RMS_CONTINUATION_FACTOR = float(os.environ.get("LOCAL_DICT_RMS_CONTINUATION_FACTOR", "0.55"))
VOICED_CONTINUATION_FACTOR = float(os.environ.get("LOCAL_DICT_VOICED_CONTINUATION_FACTOR", "0.55"))

XDG_RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/tmp/{os.getuid()}")
STATE_DIR = Path(XDG_RUNTIME_DIR) / "local-live-dictation"
PID_FILE = STATE_DIR / "loop.pid"
STOP_FILE = STATE_DIR / "stop"
TYPE_ON_FILE = STATE_DIR / "typing.on"
VOICE_COMMANDS_PID_FILE = Path(XDG_RUNTIME_DIR) / "local-voice-commands" / "loop.pid"
LOG_FILE = Path.home() / ".local" / "state" / "local-live-dictation.log"

HYPRWHSPR_CONFIG = Path.home() / ".config" / "hyprwhspr" / "config.json"
HYPRWHSPR_REALTIME_WRAPPER = Path.home() / ".local" / "bin" / "hyprwhspr-realtime-toggle.py"
VOICE_COMMANDS_CMD = Path.home() / ".local" / "bin" / "local-voice-commands.py"

HALLUCINATION_MARKERS = {
    "blank",
    "blank audio",
    "blankaudio",
    "video playback",
    "music",
    "music playing",
    "keyboard clicking",
    "silence",
    "silence please",
    "quiet",
    "inaudible",
    "foreign",
    "subtitle",
    "pause",
    "breathing",
    "inhales deeply",
    "inhale",
}

RUNNING = True


def _ensure_dirs() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)


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


def _voice_commands_running() -> bool:
    if not VOICE_COMMANDS_PID_FILE.exists():
        return False
    try:
        pid = int(VOICE_COMMANDS_PID_FILE.read_text().strip())
    except Exception:
        return False
    return _pid_alive(pid)


def _stop_voice_commands_best_effort() -> None:
    if not _voice_commands_running():
        return
    try:
        subprocess.run(
            [str(VOICE_COMMANDS_CMD), "stop"],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=20,
        )
    except Exception:
        pass


def _is_typing_enabled() -> bool:
    return TYPE_ON_FILE.exists()


def _set_typing_enabled(enabled: bool) -> None:
    if enabled:
        try:
            TYPE_ON_FILE.touch(exist_ok=True)
        except Exception:
            pass
        return
    _remove_file(TYPE_ON_FILE)


def _stop_signal_handler(_signum, _frame):
    global RUNNING
    RUNNING = False
    try:
        STOP_FILE.touch(exist_ok=True)
    except Exception:
        pass


def _remove_file(path: Path) -> None:
    try:
        path.unlink(missing_ok=True)
    except Exception:
        pass


def _collapse_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _is_hallucination(text: str) -> bool:
    normalized = re.sub(r"[^a-z ]", "", text.lower().replace("_", " ")).strip()
    return normalized in HALLUCINATION_MARKERS


def _load_hyprwhspr_config() -> dict:
    if not HYPRWHSPR_CONFIG.exists():
        return {}
    try:
        return json.loads(HYPRWHSPR_CONFIG.read_text())
    except Exception:
        return {}


def _normalize_device_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _is_generic_input_name(name: str) -> bool:
    norm = _normalize_device_text(name)
    return norm in {"default", "pipewire", "pulse", "jack"}


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

    wanted_tokens = [
        t for t in wanted_norm.split()
        if t not in {"alsa", "input", "output", "usb", "pci", "mono", "stereo", "fallback", "analog", "digital", "hw"}
    ]
    wants_mono = "mono" in wanted_norm

    def make_result(idx: int, dev: dict) -> Tuple[int, int, str]:
        rate = int(round(float(dev.get("default_samplerate", WHISPER_SAMPLE_RATE))))
        if rate <= 0:
            rate = WHISPER_SAMPLE_RATE
        return idx, rate, str(dev.get("name", f"device-{idx}"))

    # Exact-ish substring match first.
    for idx, dev in enumerate(devices):
        if dev.get("max_input_channels", 0) <= 0:
            continue
        dev_name = str(dev.get("name", ""))
        dev_norm = _normalize_device_text(dev_name)
        if wanted_norm in dev_norm or dev_norm in wanted_norm:
            return make_result(idx, dev)

    # Token overlap fallback.
    if wanted_tokens:
        best_idx = None
        best_score = -1.0
        for idx, dev in enumerate(devices):
            if dev.get("max_input_channels", 0) <= 0:
                continue
            dev_norm = _normalize_device_text(str(dev.get("name", "")))
            dev_tokens = set(dev_norm.split())
            score = float(sum(1 for tok in wanted_tokens if tok in dev_tokens))
            if wants_mono and "mono" in dev_tokens:
                score += 0.5
            if score > best_score:
                best_score = score
                best_idx = idx

        if best_idx is not None and best_score >= float(max(1, min(2, len(wanted_tokens)))):
            return make_result(best_idx, devices[best_idx])

    return None


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


def _pick_device() -> Tuple[Optional[int], Optional[int], str]:
    """Pick input device and return (device_id, capture_rate_hz, device_name)."""
    override_name = os.environ.get("LOCAL_DICT_DEVICE_NAME", "").strip()
    devices = sd.query_devices()

    def make_result(idx: int, dev: dict) -> Tuple[int, int, str]:
        rate = int(round(float(dev.get("default_samplerate", WHISPER_SAMPLE_RATE))))
        if rate <= 0:
            rate = WHISPER_SAMPLE_RATE
        return idx, rate, str(dev.get("name", f"device-{idx}"))

    # 1) Explicit env override always wins.
    if override_name:
        hit = _find_input_by_fuzzy_name(devices, override_name)
        if hit:
            return hit

    # 2) PipeWire default source name (usually the active microphone).
    pactl_source = _pactl_default_source_name()
    if pactl_source:
        hit = _find_input_by_fuzzy_name(devices, pactl_source)
        if hit:
            return hit

    # 3) hyprwhspr configured device.
    cfg = _load_hyprwhspr_config()
    maybe = cfg.get("audio_device_name")
    wanted_name = maybe.strip() if isinstance(maybe, str) else ""
    if wanted_name:
        hit = _find_input_by_fuzzy_name(devices, wanted_name)
        if hit:
            return hit

    # 4) Sounddevice default input, but avoid generic wrappers if possible.
    default_idx = None
    try:
        default_device = sd.default.device
        try:
            default_idx = default_device[0]
        except Exception:
            default_idx = default_device
        if isinstance(default_idx, (tuple, list)):
            default_idx = default_idx[0] if default_idx else None
        if default_idx is not None:
            default_idx = int(default_idx)
            dev = sd.query_devices(default_idx, kind="input")
            if dev.get("max_input_channels", 0) > 0 and not _is_generic_input_name(str(dev.get("name", ""))):
                return make_result(default_idx, dev)
    except Exception:
        default_idx = None

    # 5) First non-generic hardware-like input.
    for idx, dev in enumerate(devices):
        if dev.get("max_input_channels", 0) <= 0:
            continue
        name = str(dev.get("name", ""))
        if _is_generic_input_name(name):
            continue
        if ".monitor" in _normalize_device_text(name):
            continue
        return make_result(idx, dev)

    # 6) Generic default if we have nothing better.
    if default_idx is not None:
        try:
            dev = sd.query_devices(default_idx, kind="input")
            if dev.get("max_input_channels", 0) > 0:
                return make_result(default_idx, dev)
        except Exception:
            pass

    # 7) Last fallback: first available input.
    for idx, dev in enumerate(devices):
        if dev.get("max_input_channels", 0) > 0:
            return make_result(idx, dev)

    return None, None, ""


@dataclass
class AudioRingBuffer:
    """Thread-safe ring buffer for capture audio."""

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


@dataclass
class TranscriptSession:
    """Mutable dictation state that can be reset cleanly between sessions."""

    emitted_words: Deque[str] = field(default_factory=lambda: deque(maxlen=max(8, EMIT_HISTORY_WORDS)))
    prev_hyp_words: List[str] = field(default_factory=list)
    typer_state: dict = field(default_factory=lambda: {"last_char": "", "typed_word_pieces": []})

    def reset_pending(self) -> None:
        self.prev_hyp_words = []

    def reset_all(self) -> None:
        self.reset_pending()
        self.emitted_words.clear()
        self.typer_state["last_char"] = ""
        self.typer_state["typed_word_pieces"] = []


def _normalize_word(word: str) -> str:
    return re.sub(r"(^\W+|\W+$)", "", word.lower())


def _common_prefix_len(a: List[str], b: List[str]) -> int:
    n = min(len(a), len(b))
    i = 0
    while i < n:
        if _normalize_word(a[i]) != _normalize_word(b[i]):
            break
        i += 1
    return i


def _tail_overlap_words(prev_words: List[str], new_words: List[str], limit: int = 32) -> int:
    if not prev_words or not new_words:
        return 0

    max_overlap = min(len(prev_words), len(new_words), limit)
    for k in range(max_overlap, 0, -1):
        left = [_normalize_word(w) for w in prev_words[-k:]]
        right = [_normalize_word(w) for w in new_words[:k]]
        if left == right:
            return k
    return 0


def _compute_unseen_tail(emitted_words: Deque[str], candidate_words: List[str]) -> List[str]:
    if not candidate_words:
        return []

    history = list(emitted_words)
    overlap = _tail_overlap_words(history, candidate_words, limit=40)
    if overlap >= len(candidate_words):
        return []
    return candidate_words[overlap:]


def _count_word_like_tokens(text: str) -> int:
    return len([tok for tok in text.split() if _normalize_word(tok)])


def _split_word_pieces_for_backspace(text: str) -> List[str]:
    pieces: List[str] = []
    for match in re.finditer(r"\S+", text):
        start, end = match.span()
        piece_start = start - 1 if start > 0 and text[start - 1] == " " else start
        pieces.append(text[piece_start:end])
    return pieces


def _press_backspace(chars: int) -> None:
    if chars <= 0:
        return

    remaining = chars
    while remaining > 0:
        chunk = min(remaining, 40)
        key_events: List[str] = []
        for _ in range(chunk):
            key_events.extend(["14:1", "14:0"])  # KEY_BACKSPACE down/up

        try:
            proc = subprocess.run(
                ["ydotool", "key", "--key-delay", str(KEY_DELAY_MS), *key_events],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                timeout=20,
            )
            if proc.returncode != 0 and DEBUG:
                err = (proc.stderr or "").strip()
                print(f"[local-dict] backspace rc={proc.returncode} err={err}", flush=True)
                break
        except Exception as exc:
            if DEBUG:
                print(f"[local-dict] backspace exception: {exc}", flush=True)
            break

        remaining -= chunk


def _delete_last_typed_words(word_count: int, state: dict) -> int:
    if word_count <= 0:
        return 0

    pieces: List[str] = state.setdefault("typed_word_pieces", [])
    if not pieces:
        return 0

    to_remove = min(word_count, len(pieces))
    chars = sum(len(piece) for piece in pieces[-to_remove:])
    _press_backspace(chars)
    del pieces[-to_remove:]

    state["last_char"] = pieces[-1][-1] if pieces else ""
    return to_remove


def _resolve_tail_update(
    history_words: List[str],
    candidate_words: List[str],
    max_revise_words: int,
    min_anchor_words: int,
) -> Tuple[int, List[str]]:
    if not candidate_words:
        return 0, []

    base_overlap = _tail_overlap_words(history_words, candidate_words, limit=64)
    best_overlap = base_overlap
    best_remaining = max(0, len(history_words) - base_overlap)
    best_delete = 0

    max_delete = min(max(0, max_revise_words), len(history_words))
    for delete_n in range(1, max_delete + 1):
        trimmed = history_words[:-delete_n]
        overlap = _tail_overlap_words(trimmed, candidate_words, limit=64)
        if overlap < max(1, min_anchor_words):
            continue
        remaining = max(0, len(trimmed) - overlap)
        better = overlap > best_overlap or (overlap == best_overlap and remaining < best_remaining)
        if not better:
            continue
        best_overlap = overlap
        best_remaining = remaining
        best_delete = delete_n

    if best_overlap >= len(candidate_words):
        return 0, []

    new_words = candidate_words[best_overlap:]
    if best_delete > 0 and not new_words:
        return 0, []

    return best_delete, new_words


def _select_flush_candidate_words(pending_words: List[str], decoded_words: List[str], min_anchor_words: int) -> List[str]:
    """Pick the safest final flush candidate without appending unrelated hallucinated tails."""
    if not pending_words:
        return decoded_words
    if not decoded_words:
        return pending_words

    anchor = max(1, min_anchor_words)
    prefix = _common_prefix_len(pending_words, decoded_words)

    # Near-identical hypotheses: keep the richer one.
    if prefix >= max(1, min(len(pending_words), len(decoded_words)) - 1):
        return decoded_words if len(decoded_words) >= len(pending_words) else pending_words

    # Typical trailing revision: previous tail aligns with decoded prefix.
    overlap = _tail_overlap_words(pending_words, decoded_words, limit=64)
    if overlap >= anchor:
        return decoded_words

    # Fallback to pending if decoded tail does not anchor (likely noise/hallucination).
    return pending_words


def _commit_stable_words(
    stable_candidate: List[str],
    emitted_words: Deque[str],
    typer_state: dict,
    guard_words: int,
) -> None:
    guard = max(0, guard_words)
    if guard > 0 and len(stable_candidate) > guard:
        stable_candidate = stable_candidate[:-guard]
    elif guard > 0:
        stable_candidate = []

    if not stable_candidate:
        return

    history = list(emitted_words)
    delete_words, new_words = _resolve_tail_update(
        history_words=history,
        candidate_words=stable_candidate,
        max_revise_words=TAIL_REVISION_MAX_WORDS,
        min_anchor_words=TAIL_REVISION_MIN_ANCHOR_WORDS,
    )

    if delete_words > 0:
        removed = _delete_last_typed_words(delete_words, typer_state)
        for _ in range(removed):
            if emitted_words:
                emitted_words.pop()
        if DEBUG:
            print(f"[local-dict] revise: removed_words={removed}", flush=True)

    if len(new_words) < max(1, MIN_EMIT_WORDS):
        return

    emit_text = _collapse_whitespace(" ".join(new_words))
    if emit_text and not _is_hallucination(emit_text) and _count_word_like_tokens(emit_text) > 0:
        _type_text(emit_text, typer_state)
        for w in new_words:
            emitted_words.append(w)


def _normalize_emit_text(text: str) -> str:
    out = _collapse_whitespace(text)
    if not out:
        return ""

    style = PUNCTUATION_STYLE
    if style not in {"raw", "minimal", "adaptive"}:
        style = "adaptive"

    if style == "raw":
        return out

    # Normalize spacing around punctuation first.
    out = re.sub(r"\s+([,.;:!?])", r"\1", out)

    if style == "minimal":
        out = re.sub(r"[,:;!?]", "", out)
        out = re.sub(r"\.+$", "", out)
        return _collapse_whitespace(out)

    # Adaptive: avoid committing strong sentence punctuation on short chunks.
    words = out.split()
    if len(words) <= max(1, SHORT_SENTENCE_TERMINAL_WORDS):
        out = re.sub(r"[.?!]+$", "", out)

    out = re.sub(r"([,;:!?]){2,}", r"\1", out)
    out = re.sub(r"\.{2,}", ".", out)
    return _collapse_whitespace(out)


def _type_text(text: str, state: dict) -> None:
    out = _normalize_emit_text(text)
    if not out:
        return

    last_char = state.get("last_char", "")
    if last_char and last_char not in (" ", "\n", "\t", "(", "[", "{") and out[0] not in ".,!?;:)]}":
        out = " " + out

    try:
        proc = subprocess.run(
            ["ydotool", "type", "--key-delay", str(KEY_DELAY_MS), "--file", "-"],
            input=out,
            text=True,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            timeout=20,
        )
        if proc.returncode == 0:
            state["last_char"] = out[-1]
            pieces = _split_word_pieces_for_backspace(out)
            typed_pieces: List[str] = state.setdefault("typed_word_pieces", [])
            typed_pieces.extend(pieces)
            if DEBUG and LOG_TRANSCRIPTS:
                preview = out if len(out) <= 120 else out[:117] + "..."
                print(f"[local-dict] emit: {preview}", flush=True)
        elif DEBUG:
            err = (proc.stderr or "").strip()
            print(f"[local-dict] ydotool rc={proc.returncode} err={err}", flush=True)
    except Exception as exc:
        if DEBUG:
            print(f"[local-dict] ydotool exception: {exc}", flush=True)


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

    # Fallback linear interpolation if scipy isn't available.
    duration = audio.size / float(source_rate)
    target_samples = max(1, int(round(duration * WHISPER_SAMPLE_RATE)))
    x_old = np.linspace(0.0, 1.0, num=audio.size, endpoint=False)
    x_new = np.linspace(0.0, 1.0, num=target_samples, endpoint=False)
    return np.interp(x_new, x_old, audio).astype(np.float32, copy=False)


def _run_loop() -> int:
    _ensure_dirs()

    if _is_running() and _read_pid() != os.getpid():
        return 0

    if HYPRWHSPR_REALTIME_WRAPPER.exists():
        try:
            subprocess.run(
                [str(HYPRWHSPR_REALTIME_WRAPPER), "stop"],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass

    PID_FILE.write_text(str(os.getpid()))
    _remove_file(STOP_FILE)

    signal.signal(signal.SIGINT, _stop_signal_handler)
    signal.signal(signal.SIGTERM, _stop_signal_handler)

    try:
        print(f"[local-dict] loading model={MODEL_NAME}", flush=True)
        model = Model(
            MODEL_NAME,
            print_realtime=False,
            print_progress=False,
            print_timestamps=False,
            single_segment=False,
            no_context=True,
        )
    except Exception as exc:
        print(f"[local-dict] failed to load model: {exc}", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        return 1

    device_id, capture_rate, device_name = _pick_device()
    if device_id is None or capture_rate is None:
        print("[local-dict] no input device found", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        return 1

    print(f"[local-dict] using input device: {device_name} (id={device_id}, rate={capture_rate}Hz)", flush=True)

    max_samples = int(MAX_BUFFER_SECONDS * capture_rate)
    window_samples = int(WINDOW_SECONDS * capture_rate)

    audio_buffer = AudioRingBuffer(max_samples)
    session = TranscriptSession()

    last_process = 0.0
    last_silence_log = 0.0
    loop_start_ts = time.monotonic()
    last_voice_ts = 0.0
    typing_enabled = _is_typing_enabled()

    def _clear_audio_buffer() -> None:
        audio_buffer.clear()

    def _reset_transcript_state(clear_history: bool = False) -> None:
        if clear_history:
            session.reset_all()
            return
        session.reset_pending()

    def _current_language() -> str:
        lang = LANGUAGE_OVERRIDE.strip()
        if lang:
            return lang
        cfg_lang = _load_hyprwhspr_config().get("language")
        if isinstance(cfg_lang, str) and cfg_lang.strip():
            return cfg_lang.strip()
        return ""

    def _transcribe_window(audio_window: np.ndarray, pad_seconds: float = 0.0) -> str:
        if audio_window.size <= 0:
            return ""
        if pad_seconds > 0.0:
            pad_samples = max(1, int(round(pad_seconds * capture_rate)))
            pad = np.zeros(pad_samples, dtype=np.float32)
            audio_window = np.concatenate([audio_window.astype(np.float32, copy=False), pad], axis=0)
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
        text = _collapse_whitespace(text)
        if not text or _is_hallucination(text):
            return ""
        return text

    def _commit_words(candidate_words: List[str], guard_words: int) -> None:
        if not candidate_words:
            return
        _commit_stable_words(
            stable_candidate=candidate_words,
            emitted_words=session.emitted_words,
            typer_state=session.typer_state,
            guard_words=guard_words,
        )

    def _process_hypothesis_text(text: str) -> None:
        words = text.split()
        if not words:
            return

        if not session.prev_hyp_words:
            session.prev_hyp_words = words
            return

        overlap = _tail_overlap_words(session.prev_hyp_words, words, limit=64)
        if overlap <= 0:
            overlap = _common_prefix_len(session.prev_hyp_words, words)

        if overlap > 0:
            _commit_words(words[:overlap], STABLE_PREFIX_GUARD_WORDS)

        session.prev_hyp_words = words

    def _flush_pending(reason: str, guard_words: int, force_decode: bool = False, pad_seconds: float = 0.0) -> None:
        pending_words = list(session.prev_hyp_words)
        decoded_words: List[str] = []
        audio_now = audio_buffer.snapshot(limit_samples=window_samples)
        if audio_now.size > 0:
            should_decode = force_decode
            if not should_decode:
                rms = float(np.sqrt(np.mean(audio_now * audio_now)))
                voiced_ratio = _voiced_ratio(audio_now, RMS_THRESHOLD, VOICED_FRAME_MS, capture_rate)
                should_decode = rms >= RMS_THRESHOLD and voiced_ratio >= MIN_VOICED_RATIO

            if should_decode:
                text = _transcribe_window(audio_now, pad_seconds=pad_seconds)
                if text:
                    decoded_words = text.split()
                    if decoded_words and DEBUG and LOG_TRANSCRIPTS:
                        preview = text if len(text) <= 120 else text[:117] + "..."
                        print(f"[local-dict] flush[{reason}]: {preview}", flush=True)

        final_words = _select_flush_candidate_words(
            pending_words=pending_words,
            decoded_words=decoded_words,
            min_anchor_words=FLUSH_MIN_ANCHOR_WORDS,
        )
        _commit_words(final_words, guard_words)
        session.reset_pending()

    def audio_callback(indata, _frames, _time_info, status):
        if status:
            return
        mono = indata[:, 0].copy()
        audio_buffer.append(mono)

    print("[local-dict] started", flush=True)
    if DEBUG:
        print(
            "[local-dict] settings "
            f"step={STEP_SECONDS}s window={WINDOW_SECONDS}s max_buffer={MAX_BUFFER_SECONDS}s "
            f"rms_threshold={RMS_THRESHOLD} min_voiced_ratio={MIN_VOICED_RATIO} "
            f"voice_continuation={VOICE_CONTINUATION_SECONDS}s "
            f"guard_words={STABLE_PREFIX_GUARD_WORDS} tail_revise={TAIL_REVISION_MAX_WORDS} "
            f"flush_anchor={FLUSH_MIN_ANCHOR_WORDS} "
            f"silence_flush_guard={SILENCE_FLUSH_GUARD_WORDS} exit_flush_guard={EXIT_FLUSH_GUARD_WORDS} "
            f"final_flush_pad={FINAL_FLUSH_PAD_SECONDS}s "
            f"auto_stop_silence={AUTO_STOP_SILENCE_SECONDS}s",
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
                next_typing_enabled = _is_typing_enabled()
                if next_typing_enabled != typing_enabled:
                    if typing_enabled and not next_typing_enabled:
                        recent_voice = last_voice_ts > 0.0 and (now - last_voice_ts) <= max(0.0, EXIT_FLUSH_MAX_IDLE_SECONDS)
                        _flush_pending(
                            "typing-off",
                            EXIT_FLUSH_GUARD_WORDS,
                            force_decode=recent_voice,
                            pad_seconds=FINAL_FLUSH_PAD_SECONDS if recent_voice else 0.0,
                        )
                    typing_enabled = next_typing_enabled
                    _reset_transcript_state(clear_history=True)
                    loop_start_ts = now
                    last_voice_ts = 0.0
                    last_process = 0.0
                    _clear_audio_buffer()
                    if DEBUG:
                        state = "enabled" if typing_enabled else "disabled"
                        print(f"[local-dict] typing {state}", flush=True)

                if not typing_enabled:
                    time.sleep(0.03)
                    continue

                if now - last_process < STEP_SECONDS:
                    time.sleep(0.03)
                    continue
                last_process = now

                audio = audio_buffer.snapshot(limit_samples=window_samples)
                if audio.size <= 0:
                    continue

                rms = float(np.sqrt(np.mean(audio * audio)))
                voiced_ratio = _voiced_ratio(audio, RMS_THRESHOLD, VOICED_FRAME_MS, capture_rate)
                continuation_open = last_voice_ts > 0.0 and (now - last_voice_ts) <= max(0.0, VOICE_CONTINUATION_SECONDS)

                rms_threshold = RMS_THRESHOLD
                voiced_threshold = MIN_VOICED_RATIO
                if continuation_open:
                    rms_threshold *= max(0.05, RMS_CONTINUATION_FACTOR)
                    voiced_threshold *= max(0.05, VOICED_CONTINUATION_FACTOR)

                if rms < rms_threshold or voiced_ratio < voiced_threshold:
                    silence_for = (now - last_voice_ts) if last_voice_ts > 0.0 else (now - loop_start_ts)
                    if last_voice_ts > 0.0 and silence_for >= SILENCE_RESET_SECONDS:
                        _flush_pending(
                            "silence",
                            SILENCE_FLUSH_GUARD_WORDS,
                            force_decode=True,
                            pad_seconds=FINAL_FLUSH_PAD_SECONDS,
                        )
                        last_voice_ts = 0.0
                        loop_start_ts = now

                    if AUTO_STOP_SILENCE_SECONDS > 0 and silence_for >= AUTO_STOP_SILENCE_SECONDS:
                        print(f"[local-dict] auto-disable typing after {silence_for:.1f}s of inactivity", flush=True)
                        _set_typing_enabled(False)
                        typing_enabled = False
                        _reset_transcript_state(clear_history=True)
                        loop_start_ts = now
                        last_voice_ts = 0.0
                        _clear_audio_buffer()
                        continue

                    if DEBUG and (now - last_silence_log) >= 5.0:
                        print(
                            f"[local-dict] waiting for voice rms={rms:.5f} voiced_ratio={voiced_ratio:.2f} "
                            f"thresholds=({rms_threshold:.5f},{voiced_threshold:.2f})",
                            flush=True,
                        )
                        last_silence_log = now
                    continue

                text = _transcribe_window(audio)
                if not text:
                    continue

                last_voice_ts = now

                if DEBUG and LOG_TRANSCRIPTS:
                    preview = text if len(text) <= 120 else text[:117] + "..."
                    print(f"[local-dict] heard: {preview}", flush=True)

                _process_hypothesis_text(text)

            exit_idle = (time.monotonic() - last_voice_ts) if last_voice_ts > 0.0 else (time.monotonic() - loop_start_ts)
            if typing_enabled and exit_idle <= max(0.0, EXIT_FLUSH_MAX_IDLE_SECONDS):
                _flush_pending("exit", EXIT_FLUSH_GUARD_WORDS, force_decode=True, pad_seconds=FINAL_FLUSH_PAD_SECONDS)

    finally:
        print("[local-dict] stopped", flush=True)
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        _remove_file(TYPE_ON_FILE)

    return 0


def _daemon_start() -> int:
    _ensure_dirs()
    _stop_voice_commands_best_effort()
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


def _start() -> int:
    _ensure_dirs()
    _stop_voice_commands_best_effort()
    _remove_file(STOP_FILE)
    was_typing_enabled = _is_typing_enabled()
    _set_typing_enabled(True)

    if _is_running():
        print("already-on" if was_typing_enabled else "typing-on")
        return 0

    return _daemon_start()


def _stop() -> int:
    _ensure_dirs()
    if not _is_running():
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        _remove_file(TYPE_ON_FILE)
        print("already-off")
        return 0

    if not _is_typing_enabled():
        print("already-off")
        return 0

    _set_typing_enabled(False)
    print("typing-off")
    return 0


def _daemon_stop() -> int:
    _ensure_dirs()
    pid = _read_pid()
    if not pid or not _pid_alive(pid):
        _remove_file(PID_FILE)
        _remove_file(STOP_FILE)
        _remove_file(TYPE_ON_FILE)
        print("already-daemon-stopped")
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
    _remove_file(TYPE_ON_FILE)
    print("daemon-stopped")
    return 0


def _status() -> int:
    running = _is_running()
    typing = running and _is_typing_enabled()
    print(f"running={1 if running else 0} typing={1 if typing else 0}")
    return 0


def main() -> int:
    cmd = (sys.argv[1] if len(sys.argv) > 1 else "toggle").lower()
    if cmd == "run":
        return _run_loop()
    if cmd == "start":
        return _start()
    if cmd == "stop":
        return _stop()
    if cmd in {"daemon-start", "model-start"}:
        return _daemon_start()
    if cmd in {"daemon-stop", "model-stop"}:
        return _daemon_stop()
    if cmd == "status":
        return _status()
    if cmd == "toggle":
        return _stop() if (_is_running() and _is_typing_enabled()) else _start()

    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
