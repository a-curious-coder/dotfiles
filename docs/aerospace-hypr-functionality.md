# AeroSpace + Sketchybar Hypr-Style Functionality

This document captures what is currently implemented in your macOS setup to mirror your Hyprland workflow.

## Keybinding Discovery (Hypr Parity)

- `cmd+h`: open this functionality/keybinding guide (Hypr-style key-hints equivalent)
- `cmd+shift+k`: open Spotlight-style searchable keybinding chooser (Hammerspoon), with clipboard copy on select

Notes:
- `cmd+h` now prioritizes key hints.
- Left focus remains available on `cmd+left`.

## Implemented Functionality

- Dwindle-like split approximation on focus/new-window events via `auto-split-orientation.sh`
- Reorganize current workspace tree (`flatten + balance`) on `cmd+shift+space`
- Toggle current window floating/tiling on `cmd+space`
- Toggle workspace-wide all-float mode on `cmd+alt+space`
- Special workspace scratchpad (`S`) toggle/send:
  - toggle: `cmd+u`
  - send focused window: `cmd+shift+u`
- Dropdown terminal toggle on `cmd+shift+enter`
- Workspace back-and-forth on `cmd+backslash`
- Directional focus/move/swap/resize parity coverage
- App/workspace routing via AeroSpace `on-window-detected` rules
- Dialog/PiP float-size-center approximations via:
  - `apply-focused-window-rules.sh`
  - Hammerspoon window rules
- Sketchybar parity enhancements:
  - workspace click + scroll switching
  - focused-workspace window summary list (`windowlist`) that auto-hides when no windows are present
- Cmd-drag support via Hammerspoon:
  - `cmd + left-drag`: move focused window
  - `cmd + right-drag`: resize focused window

## Side-by-Side Keymap (Hypr vs AeroSpace)

| Area | Hypr | AeroSpace / macOS | Status |
|---|---|---|---|
| Key hints | `SUPER+H` | `cmd+h` | Matched |
| Keybind search | `SUPER+SHIFT+K` | `cmd+shift+k` | Matched |
| Terminal | `SUPER+Return` | `cmd+enter` | Matched |
| Browser new window | `SUPER+B` (custom open) | `cmd+b` | Approximated |
| Fullscreen | `SUPER+SHIFT+F` | `cmd+shift+f` | Matched |
| Fake fullscreen | `SUPER+CTRL+F` | `cmd+ctrl+f` (`macos-native-fullscreen`) | Approximated |
| Float toggle | `SUPER+Space` | `cmd+space` | Matched intent |
| All-float workspace | `SUPER+ALT+Space` | `cmd+alt+space` | Matched intent |
| Dropdown terminal | `SUPER+SHIFT+Return` | `cmd+shift+enter` | Matched intent |
| Scratchpad toggle | `SUPER+U` | `cmd+u` | Matched intent |
| Send to scratchpad | `SUPER+SHIFT+U` | `cmd+shift+u` | Matched intent |
| Focus left/down/up/right | `SUPER+arrows` | `cmd+arrows` | Matched |
| Focus down/up/right (vim keys) | `SUPER+J/K/L` | `cmd+j/k/l` | Partial |
| Move window | `SUPER+CTRL+arrows` | `cmd+ctrl+arrows` | Matched |
| Move window (vim keys) | `SUPER+CTRL+H/J/K/L` | `cmd+ctrl+h/j/k/l` | Matched |
| Swap window | `SUPER+ALT+arrows` | `cmd+alt+arrows` | Matched |
| Swap window (vim keys) | `SUPER+ALT+H/J/K/L` | `cmd+alt+h/j/k/l` | Matched |
| Resize window | `SUPER+SHIFT+arrows` | `cmd+shift+arrows` | Matched |
| Toggle split | `SUPER+SHIFT+I` | `cmd+shift+i` | Matched |
| Workspace next/prev | `SUPER+tab`, `SUPER+SHIFT+tab` | `cmd+tab`, `cmd+shift+tab` | Matched intent |
| Workspace next/prev alt keys | `SUPER+,` / `SUPER+.` | `cmd+,` / `cmd+.` | Matched |
| Workspace back-and-forth | enabled setting | `cmd+backslash` | Added |
| Workspace select | `SUPER+[1..0]` | `cmd+[1..9], cmd+e, cmd+0(S)` | Approximated |
| Move window + follow | `SUPER+SHIFT+[num]` | `cmd+shift+[num/e/0]` | Matched intent |
| Move window silent | `SUPER+CTRL+[num]` | `cmd+ctrl+[num/e/0]` | Matched intent |
| Move workspace to next monitor | custom `ALT+SHIFT+TAB` | `alt+shift+tab` | Matched |
| Reorganize layout | (manual scripts) | `cmd+shift+space` | Added |
| Cmd-drag move/resize | native bindm behavior in Hypr | Hammerspoon cmd-drag | Approximated |

## Current Gaps (Still Not 1:1 with Hypr)

- No true `togglegroup`/group-tab equivalent in AeroSpace
- No true pseudotile mode equivalent
- No native `pin + keep_aspect_ratio + idle_inhibit` parity in AeroSpace
- Rule engine parity is approximate for complex title/class behaviors

## Files Involved

- `aerospace/.config/aerospace/aerospace.toml`
- `aerospace/.config/aerospace/scripts/*.sh`
- `sketchybar/.config/sketchybar/sketchybarrc`
- `sketchybar/.config/sketchybar/plugins/*.sh`
- `hammerspoon/.hammerspoon/init.lua`

## Quick Validation Checklist

- Press `cmd+h` and confirm this doc opens.
- Press `cmd+shift+k` and confirm searchable key list opens as a Spotlight-style chooser.
- Create 3-5 windows and confirm split behavior remains alternating/dwindle-like.
- Toggle scratchpad (`cmd+u`) and send a window to scratchpad (`cmd+shift+u`).
- Toggle dropdown terminal (`cmd+shift+enter`).
- Use `cmd+shift+arrows` to resize.
- Use `cmd + left-drag` and `cmd + right-drag` to move/resize floating windows.
