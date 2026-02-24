# Transcription Stack

This directory is the version-controlled source for the offline dictation setup currently running on host `lp`.

## Folder layout

- `scripts/local-live-dictation.py`
  - Live dictation daemon (offline Whisper + ydotool typing) with explicit `AudioRingBuffer` + `TranscriptSession` state.
- `scripts/hyprwhspr-double-left-ctrl.py`
  - Global double-`Ctrl` hotkey listener for dictation/command mode switching.
- `scripts/local-live-dictation-eval.py`
  - Deterministic replay/evaluation tool for recorded audio.
- `scripts/local-live-dictation-waybar-status.py`
  - Waybar JSON status provider (`` off / `` warm / `` on).
- `scripts/local-voice-commands.py`
  - Offline voice command daemon (Hyprland app/window actions, web search, and custom commands/scripts).
- `systemd/hyprwhspr-double-left-ctrl.service`
  - User service for the dual hotkey listener.
- `config/hyprwhspr-config.json`
  - Snapshot of hyprwhspr config from `lp`.
- `config/local-voice-commands-config.json`
  - App alias/action mapping for command mode.
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

- Double left `Ctrl` toggles **typing mode**.
- Double right `Ctrl` toggles **voice-command mode**.
- Modes are mutually exclusive: starting one stops the other.
- Voice-command mode is enabled by default at login/service start.
- The Whisper model daemon stays loaded between dictation sessions.
- Waybar shows speech mode state in `custom/dictation-model` (`` off, `` warm, `` dictation, `` commands).
- `~/.local/bin/local-live-dictation.py start`
  - Ensure daemon is running and enable typing mode.
- `~/.local/bin/local-live-dictation.py stop`
  - Disable typing mode but keep daemon/model loaded.
- `~/.local/bin/local-live-dictation.py daemon-stop`
  - Fully stop daemon/model.
- `~/.local/bin/local-live-dictation.py status`
  - Print `running=<0|1> typing=<0|1>`.
- `~/.local/bin/local-voice-commands.py start|stop|status`
  - Start/stop/check command-listening mode.
- `~/.local/bin/local-voice-commands.py simulate "open terminal"`
  - Run command parser/executor without microphone capture (for quick rule testing).

### Voice command phrases

- `open terminal`
- `open browser`
- `show obsidian`
- `open vlc player`
- `focus vlc`
- `show discord`
- `close current window`
- `search for rust ownership model`
- `close terminal`
- `close browser`
- `next workspace`
- `switch monitor`
- `enhance` / `zoom in`
- `enhance times 5` (multiplicative: `enhance times 3 times 3` => 9 zoom steps)
- `zoom out` / `decrease zoom`
- `zoom out times 4`
- `move current window to workspace 2`
- `send vlc to workspace 3`
- `toggle floating`
- `update discord`

Command mode now executes on stable repeated command hypotheses while you speak (not only at final silence), which avoids losing valid commands to trailing filler words.
`open terminal` is mapped to `ghostty`; `open browser` is mapped to `brave` in the default config.
`focus <app>` focuses only (it will not auto-open the app if no matching window exists).
`move/send <app> to workspace <n>` and `move/send current window to workspace <n>` are supported.
If multiple windows match an app, the command targets a window on the active workspace first, otherwise the first matching window.

To scale app support, edit `~/.config/local-voice-commands/config.json` (`apps[*].aliases`, `apps[*].launch`, and `apps[*].match`).
Custom commands live under `commands[*]` and support:
- `dispatch`: Hyprland dispatcher arguments (for example `workspace +1`, `togglefloating`, `fullscreen 1`)
- `dispatches`: list of Hyprland dispatches executed in order (for example move window then focus monitor)
- `exec`: shell command/script (for example `~/Projects/personal/dotfiles/discord_install.sh`)

`update discord` now follows deterministic behavior in `discord_install.sh`:
- if local and remote versions match: no app close and fast exit
- if update is needed: close Discord, update, and relaunch only if it was running before

Command mode live execution tuning:
- `LOCAL_VCMD_COMMAND_CONFIRM_REPETITIONS` (default `1`)
- `LOCAL_VCMD_COMMAND_COOLDOWN_SECONDS` (default `1.5`)
- `LOCAL_VCMD_ZOOM_KEY_DELAY_MS` (default `14`)
- `LOCAL_VCMD_ZOOM_STEP_SLEEP_MS` (default `40`)

## Key realtime tuning vars

- `LOCAL_DICT_STABLE_PREFIX_GUARD_WORDS` (default `0`)
  - Holds back the last N words from each stable chunk so uncertain words are not committed too early.
- `LOCAL_DICT_TAIL_REVISION_MAX_WORDS` (default `6`)
  - Maximum number of recently typed words that may be replaced when Whisper revises a phrase.
- `LOCAL_DICT_TAIL_REVISION_MIN_ANCHOR_WORDS` (default `3`)
  - Minimum exact anchor words required before a tail revision is allowed.
- `LOCAL_DICT_FLUSH_MIN_ANCHOR_WORDS` (default `2`)
  - Minimum anchor words needed when choosing between pending and final forced-decode hypotheses at utterance end.
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
- `LOCAL_DICT_VOICE_CONTINUATION_SECONDS` (default `1.8`)
  - Time window after recent speech where relaxed voice gating is used to avoid clipping quieter trailing words.
- `LOCAL_DICT_RMS_CONTINUATION_FACTOR` / `LOCAL_DICT_VOICED_CONTINUATION_FACTOR` (defaults `0.55` / `0.55`)
  - Multipliers applied during continuation gating.
- `LOCAL_DICT_PUNCTUATION_STYLE` (default `adaptive`)
  - `raw`, `minimal`, or `adaptive` punctuation behavior.
- `LOCAL_DICT_ENABLE_START_SOUND` (default `0`)
  - Start sound is disabled by default to avoid clipping the first words while dictation warms up.
