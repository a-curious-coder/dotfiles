# yabai Migration (macOS)

This repo now uses `yabai + skhd + sketchybar` for macOS tiling.

## Scope

- Closest practical behavior to current Hyprland setup
- Hard `cmd + drag` window move/resize
- Workspace routing parity for primary app categories
- Sketchybar workspace module migration from AeroSpace to yabai

## Pre-checks

```bash
# Ensure repo is stowed with the new packages
stow yabai skhd sketchybar calibre-macos

# Start services
yabai --start-service
skhd --start-service
```

## SIP + scripting-addition (required for full parity)

For full yabai window-server control, follow official docs:

- https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection
- https://github.com/asmvik/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition

After completion:

```bash
yabai --restart-service
skhd --reload
```

## What was migrated

### Window behavior

- BSP layout (`layout bsp`)
- Preserve-split style behavior (`auto_balance off`, `window_placement first_child`)
- `cmd + drag` enabled (`mouse_modifier cmd`, move/resize actions)

### Workspace routing

Mapped from Hypr tags:

- Browser -> space `1`
- Terminal -> space `2`
- Obsidian/screenshare -> space `4`
- Game store -> space `5`
- Virtualization -> space `6`
- IM -> space `7`
- Multimedia -> space `9`

### Sketchybar

- Workspace plugin now supports both backends
- Prefers yabai when available
- Uses event-driven refresh + low-frequency safety refresh

## Test checklist

1. `cmd + drag` moves windows.
2. `cmd + right-click drag` resizes windows.
3. `cmd + h/j/k/l` focuses directional neighbors.
4. `cmd + shift + h/j/k/l` warps windows.
5. Open Brave/Ghostty/Discord/Spotify and verify space routing.
6. Sketchybar workspace labels follow focused/visible spaces.
7. Sleep/wake, then verify yabai/skhd still active.

## Rollback

If needed, revert to legacy AeroSpace package:

```bash
stow -D yabai skhd
stow aerospace sketchybar

# Optional: stop new services
yabai --stop-service || true
skhd --stop-service || true
```

Then restart Sketchybar and AeroSpace.
