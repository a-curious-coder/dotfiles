# Transcription Stack

This directory is the version-controlled source for the offline dictation setup currently running on host `lp`.

## Folder layout

- `scripts/local-live-dictation.py`
  - Live dictation daemon (offline Whisper + ydotool typing).
- `scripts/hyprwhspr-double-left-ctrl.py`
  - Global double-`Ctrl` hotkey listener and typing on/off toggle.
- `scripts/local-live-dictation-eval.py`
  - Deterministic replay/evaluation tool for recorded audio.
- `scripts/local-live-dictation-waybar-status.py`
  - Waybar JSON status provider (`DICT OFF` / `DICT WARM` / `DICT ON`).
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

## Runtime control

- Double-`Ctrl` now toggles **typing mode**.
- The Whisper model daemon stays loaded between dictation sessions.
- Waybar shows model/typing state in `custom/dictation-model`.
- `~/.local/bin/local-live-dictation.py start`
  - Ensure daemon is running and enable typing mode.
- `~/.local/bin/local-live-dictation.py stop`
  - Disable typing mode but keep daemon/model loaded.
- `~/.local/bin/local-live-dictation.py daemon-stop`
  - Fully stop daemon/model.
- `~/.local/bin/local-live-dictation.py status`
  - Print `running=<0|1> typing=<0|1>`.

## Key realtime tuning vars

- `LOCAL_DICT_STABLE_PREFIX_GUARD_WORDS` (default `0`)
  - Holds back the last N words from each stable chunk so uncertain words are not committed too early.
- `LOCAL_DICT_TAIL_REVISION_MAX_WORDS` (default `3`)
  - Maximum number of recently typed words that may be replaced when Whisper revises a phrase.
- `LOCAL_DICT_TAIL_REVISION_MIN_ANCHOR_WORDS` (default `2`)
  - Minimum exact anchor words required before a tail revision is allowed.
- `LOCAL_DICT_SILENCE_FLUSH_GUARD_WORDS` (default `0`)
  - On silence boundary, flush pending words but keep the final N words uncommitted to reduce random trailing tokens.
- `LOCAL_DICT_EXIT_FLUSH_GUARD_WORDS` (default `0`)
  - On explicit stop/exit, flushes pending words with this guard value.
- `LOCAL_DICT_EXIT_FLUSH_MAX_IDLE_SECONDS` (default `2.5`)
  - Exit flush only runs if speech was recent, which helps avoid stale random trailing output.
- `LOCAL_DICT_FINAL_FLUSH_PAD_SECONDS` (default `0.70`)
  - Adds short trailing silence during forced flush so final words are less likely to be cut off.
- `LOCAL_DICT_AUTO_STOP_SILENCE_SECONDS` (default `12.0`)
  - Auto-disables typing after inactivity while leaving the daemon/model running.
- `LOCAL_DICT_PUNCTUATION_STYLE` (default `adaptive`)
  - `raw`, `minimal`, or `adaptive` punctuation behavior.
- `LOCAL_DICT_ENABLE_START_SOUND` (default `0`)
  - Start sound is disabled by default to avoid clipping the first words while dictation warms up.
