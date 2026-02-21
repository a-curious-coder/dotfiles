#!/home/groot/.local/share/hyprwhspr/venv/bin/python
"""Evaluate local-live-dictation behavior on a recorded audio file."""

from __future__ import annotations

import argparse
import importlib.util
import re
import subprocess
import sys
from collections import deque
from pathlib import Path
from typing import Deque, List, Optional, Tuple

import numpy as np
from pywhispercpp.model import Model

SCRIPT_PATH = Path.home() / ".local" / "bin" / "local-live-dictation.py"


def _load_live_module(path: Path):
    spec = importlib.util.spec_from_file_location("local_live_dictation", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _decode_audio_to_f32_mono(path: Path, sample_rate: int) -> np.ndarray:
    cmd = [
        "ffmpeg",
        "-nostdin",
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        str(path),
        "-ac",
        "1",
        "-ar",
        str(sample_rate),
        "-f",
        "f32le",
        "-",
    ]
    try:
        raw = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(f"ffmpeg decode failed: {exc}") from exc

    audio = np.frombuffer(raw, dtype=np.float32)
    if audio.size == 0:
        raise RuntimeError("decoded audio is empty")
    return audio


def _collapse_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _norm_text_words(text: str) -> List[str]:
    cleaned = re.sub(r"[^a-z0-9\s']", " ", text.lower())
    return [w for w in cleaned.split() if w]


def _word_error_rate(reference: str, hypothesis: str) -> Tuple[float, int, int, int]:
    ref = _norm_text_words(reference)
    hyp = _norm_text_words(hypothesis)

    if not ref:
        return (0.0 if not hyp else 1.0), 0, len(hyp), 0

    rows = len(ref) + 1
    cols = len(hyp) + 1
    dp = [[0] * cols for _ in range(rows)]

    for i in range(rows):
        dp[i][0] = i
    for j in range(cols):
        dp[0][j] = j

    for i in range(1, rows):
        for j in range(1, cols):
            cost = 0 if ref[i - 1] == hyp[j - 1] else 1
            dp[i][j] = min(
                dp[i - 1][j] + 1,
                dp[i][j - 1] + 1,
                dp[i - 1][j - 1] + cost,
            )

    edits = dp[-1][-1]
    wer = edits / max(1, len(ref))
    return wer, len(ref), len(hyp), edits


def _transcribe_text(model: Model, audio: np.ndarray, language: str) -> str:
    kwargs = {}
    if language:
        kwargs["language"] = language
    segments = model.transcribe(audio, n_processors=None, **kwargs)
    text = " ".join(seg.text for seg in segments if getattr(seg, "text", ""))
    return _collapse_ws(text)


def _simulate_realtime(
    live,
    model: Model,
    audio: np.ndarray,
    sample_rate: int,
    step_seconds: float,
    window_seconds: float,
    rms_threshold: float,
    silence_reset_seconds: float,
    silence_flush_guard_words: int,
    guard_words: int,
    tail_revision_max_words: int,
    tail_revision_min_anchor_words: int,
    emit_history_words: int,
    language: str,
    verbose: bool,
) -> Tuple[str, List[str]]:
    step_samples = max(1, int(round(step_seconds * sample_rate)))
    window_samples = max(step_samples, int(round(window_seconds * sample_rate)))
    duration = len(audio) / float(sample_rate)

    prev_hyp_words: List[str] = []
    emitted_words: Deque[str] = deque(maxlen=max(8, emit_history_words))
    out_words: List[str] = []

    last_voice_ts = 0.0
    trace: List[str] = []

    end = step_samples
    while end <= len(audio):
        clip = audio[max(0, end - window_samples) : end]
        now = end / float(sample_rate)

        if clip.size <= 0:
            end += step_samples
            continue

        rms = float(np.sqrt(np.mean(clip * clip)))
        voiced_ratio = 1.0
        if hasattr(live, "_voiced_ratio"):
            try:
                voiced_ratio = float(
                    live._voiced_ratio(
                        clip,
                        rms_threshold,
                        int(getattr(live, "VOICED_FRAME_MS", 30)),
                        sample_rate,
                    )
                )
            except Exception:
                voiced_ratio = 1.0

        min_voiced_ratio = float(getattr(live, "MIN_VOICED_RATIO", 0.0))
        if rms < rms_threshold or voiced_ratio < min_voiced_ratio:
            if last_voice_ts > 0.0 and (now - last_voice_ts) >= silence_reset_seconds:
                if prev_hyp_words:
                    flush_candidate = list(prev_hyp_words)
                    guard = max(0, int(silence_flush_guard_words))
                    if guard > 0 and len(flush_candidate) > guard:
                        flush_candidate = flush_candidate[:-guard]
                    elif guard > 0:
                        flush_candidate = []

                    if flush_candidate:
                        delete_words = 0
                        new_words = []
                        if hasattr(live, "_resolve_tail_update"):
                            delete_words, new_words = live._resolve_tail_update(
                                history_words=list(emitted_words),
                                candidate_words=flush_candidate,
                                max_revise_words=tail_revision_max_words,
                                min_anchor_words=tail_revision_min_anchor_words,
                            )
                        else:
                            new_words = live._compute_unseen_tail(emitted_words, flush_candidate)

                        if delete_words > 0:
                            delete_words = min(delete_words, len(out_words), len(emitted_words))
                            if delete_words > 0:
                                del out_words[-delete_words:]
                                for _ in range(delete_words):
                                    emitted_words.pop()
                                if verbose:
                                    trace.append(f"t={now:5.2f}s revise: delete {delete_words} words")

                        min_emit_words = max(1, int(getattr(live, "MIN_EMIT_WORDS", 1)))
                        if len(new_words) >= min_emit_words:
                            emitted_words.extend(new_words)
                            out_words.extend(new_words)
                            if verbose:
                                trace.append(f"t={now:5.2f}s emit: {' '.join(new_words)}")
                prev_hyp_words = []
            end += step_samples
            continue

        last_voice_ts = now

        text = _transcribe_text(model, clip, language)
        if not text or live._is_hallucination(text):
            end += step_samples
            continue

        words = text.split()
        if verbose:
            trace.append(f"t={now:5.2f}s heard: {text}")

        if not prev_hyp_words:
            prev_hyp_words = words
            end += step_samples
            continue

        overlap = live._tail_overlap_words(prev_hyp_words, words, limit=64)
        if overlap <= 0:
            overlap = live._common_prefix_len(prev_hyp_words, words)

        if overlap > 0:
            stable_candidate = words[:overlap]
            guard = max(0, int(guard_words))
            if guard > 0 and len(stable_candidate) > guard:
                stable_candidate = stable_candidate[:-guard]
            elif guard > 0:
                stable_candidate = []

            if not stable_candidate:
                prev_hyp_words = words
                end += step_samples
                continue

            delete_words = 0
            new_words = []
            if hasattr(live, "_resolve_tail_update"):
                delete_words, new_words = live._resolve_tail_update(
                    history_words=list(emitted_words),
                    candidate_words=stable_candidate,
                    max_revise_words=tail_revision_max_words,
                    min_anchor_words=tail_revision_min_anchor_words,
                )
            else:
                new_words = live._compute_unseen_tail(emitted_words, stable_candidate)

            if delete_words > 0:
                delete_words = min(delete_words, len(out_words), len(emitted_words))
                if delete_words > 0:
                    del out_words[-delete_words:]
                    for _ in range(delete_words):
                        emitted_words.pop()
                    if verbose:
                        trace.append(f"t={now:5.2f}s revise: delete {delete_words} words")

            min_emit_words = max(1, int(getattr(live, "MIN_EMIT_WORDS", 1)))
            if len(new_words) >= min_emit_words:
                emitted_words.extend(new_words)
                out_words.extend(new_words)
                if verbose:
                    trace.append(f"t={now:5.2f}s emit: {' '.join(new_words)}")

        prev_hyp_words = words
        end += step_samples

    if prev_hyp_words:
        flush_candidate = list(prev_hyp_words)
        guard = max(0, int(silence_flush_guard_words))
        if guard > 0 and len(flush_candidate) > guard:
            flush_candidate = flush_candidate[:-guard]
        elif guard > 0:
            flush_candidate = []

        if flush_candidate:
            delete_words = 0
            new_words = []
            if hasattr(live, "_resolve_tail_update"):
                delete_words, new_words = live._resolve_tail_update(
                    history_words=list(emitted_words),
                    candidate_words=flush_candidate,
                    max_revise_words=tail_revision_max_words,
                    min_anchor_words=tail_revision_min_anchor_words,
                )
            else:
                new_words = live._compute_unseen_tail(emitted_words, flush_candidate)

            if delete_words > 0:
                delete_words = min(delete_words, len(out_words), len(emitted_words))
                if delete_words > 0:
                    del out_words[-delete_words:]
                    for _ in range(delete_words):
                        emitted_words.pop()
                    if verbose:
                        trace.append(f"t={duration:5.2f}s revise: delete {delete_words} words")

            min_emit_words = max(1, int(getattr(live, "MIN_EMIT_WORDS", 1)))
            if len(new_words) >= min_emit_words:
                emitted_words.extend(new_words)
                out_words.extend(new_words)
                if verbose:
                    trace.append(f"t={duration:5.2f}s emit: {' '.join(new_words)}")

    return _collapse_ws(" ".join(out_words)), trace


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--audio", required=True, help="Path to input audio/video file")
    p.add_argument("--reference", default="", help="Expected phrase/text")
    p.add_argument("--reference-file", default="", help="Path to file containing expected text")
    p.add_argument("--model", default="base.en", help="Whisper model name")
    p.add_argument("--language", default="en", help="Language override (e.g. en)")
    p.add_argument("--sample-rate", type=int, default=16000)
    p.add_argument("--step-seconds", type=float, default=0.6)
    p.add_argument("--window-seconds", type=float, default=4.0)
    p.add_argument("--rms-threshold", type=float, default=0.00035)
    p.add_argument("--silence-reset-seconds", type=float, default=1.2)
    p.add_argument("--silence-flush-guard-words", type=int, default=0)
    p.add_argument("--guard-words", type=int, default=0)
    p.add_argument("--tail-revision-max-words", type=int, default=3)
    p.add_argument("--tail-revision-min-anchor-words", type=int, default=2)
    p.add_argument("--emit-history-words", type=int, default=72)
    p.add_argument("--verbose", action="store_true")
    return p


def main() -> int:
    args = _build_parser().parse_args()

    audio_path = Path(args.audio).expanduser().resolve()
    if not audio_path.exists():
        print(f"audio file not found: {audio_path}", file=sys.stderr)
        return 2

    reference = args.reference
    if args.reference_file:
        ref_file = Path(args.reference_file).expanduser().resolve()
        if not ref_file.exists():
            print(f"reference file not found: {ref_file}", file=sys.stderr)
            return 2
        reference = ref_file.read_text().strip()

    live = _load_live_module(SCRIPT_PATH)

    print(f"[eval] decoding: {audio_path}")
    audio = _decode_audio_to_f32_mono(audio_path, args.sample_rate)
    duration = audio.size / float(args.sample_rate)
    print(f"[eval] audio duration: {duration:.2f}s @ {args.sample_rate}Hz")

    print(f"[eval] loading model={args.model}")
    model = Model(
        args.model,
        print_realtime=False,
        print_progress=False,
        print_timestamps=False,
        single_segment=False,
        no_context=True,
    )

    full_text = _transcribe_text(model, audio, args.language)
    simulated_text, trace = _simulate_realtime(
        live=live,
        model=model,
        audio=audio,
        sample_rate=args.sample_rate,
        step_seconds=args.step_seconds,
        window_seconds=args.window_seconds,
        rms_threshold=args.rms_threshold,
        silence_reset_seconds=args.silence_reset_seconds,
        silence_flush_guard_words=args.silence_flush_guard_words,
        guard_words=args.guard_words,
        tail_revision_max_words=args.tail_revision_max_words,
        tail_revision_min_anchor_words=args.tail_revision_min_anchor_words,
        emit_history_words=args.emit_history_words,
        language=args.language,
        verbose=args.verbose,
    )

    print("\n=== Full Transcript (single-pass) ===")
    print(full_text or "<empty>")

    print("\n=== Simulated Realtime Output ===")
    print(simulated_text or "<empty>")

    if args.verbose and trace:
        print("\n=== Realtime Trace ===")
        for line in trace:
            print(line)

    if reference:
        wer_full, ref_n, hyp_n_full, edits_full = _word_error_rate(reference, full_text)
        wer_sim, _, hyp_n_sim, edits_sim = _word_error_rate(reference, simulated_text)

        print("\n=== Accuracy vs Reference ===")
        print(f"reference_words={ref_n}")
        print(f"full_pass_wer={wer_full:.3f} edits={edits_full} hyp_words={hyp_n_full}")
        print(f"simulated_rt_wer={wer_sim:.3f} edits={edits_sim} hyp_words={hyp_n_sim}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
