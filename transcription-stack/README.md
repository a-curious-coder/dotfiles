# Transcription Stack

This directory is the version-controlled source for the offline dictation setup currently running on host `lp`.

## Folder layout

- `scripts/local-live-dictation.py`
  - Live dictation daemon (offline Whisper + ydotool typing).
- `scripts/hyprwhspr-double-left-ctrl.py`
  - Global double-`Ctrl` hotkey listener and start/stop trigger.
- `scripts/local-live-dictation-eval.py`
  - Deterministic replay/evaluation tool for recorded audio.
- `systemd/hyprwhspr-double-left-ctrl.service`
  - User service for the hotkey listener.
- `config/hyprwhspr-config.json`
  - Snapshot of hyprwhspr config from `lp`.
- `tools/sync-from-lp.sh`
  - Pull latest runtime files from `lp` into this folder.
- `tools/deploy-to-lp.sh`
  - Push files from this folder to `lp` and restart the hotkey service.
- `notes/import.sha256`
  - Snapshot checksums from initial import.

## Typical workflow

1. Pull current state from `lp`:

```bash
./transcription-stack/tools/sync-from-lp.sh
```

2. Edit files in this directory.

3. Push updates to `lp`:

```bash
./transcription-stack/tools/deploy-to-lp.sh
```

4. Validate on `lp`:

```bash
ssh lp '~/.local/bin/local-live-dictation-eval.py --audio ~/dictation-test.wav --reference "<expected text>"'
ssh lp 'tail -n 120 ~/.local/state/local-live-dictation.log'
```

## Zoxide

To make this folder addressable directly with zoxide:

```bash
zoxide add "$(pwd)/transcription-stack"
```

## Key realtime tuning vars

- `LOCAL_DICT_STABLE_PREFIX_GUARD_WORDS` (default `2`)
  - Holds back the last N words from each stable chunk so uncertain words are not committed too early.
- `LOCAL_DICT_TAIL_REVISION_MAX_WORDS` (default `3`)
  - Maximum number of recently typed words that may be replaced when Whisper revises a phrase.
- `LOCAL_DICT_TAIL_REVISION_MIN_ANCHOR_WORDS` (default `2`)
  - Minimum exact anchor words required before a tail revision is allowed.
- `LOCAL_DICT_SILENCE_FLUSH_GUARD_WORDS` (default `1`)
  - On silence boundary, flush pending words but keep the final N words uncommitted to reduce random trailing tokens.
- `LOCAL_DICT_PUNCTUATION_STYLE` (default `adaptive`)
  - `raw`, `minimal`, or `adaptive` punctuation behavior.
