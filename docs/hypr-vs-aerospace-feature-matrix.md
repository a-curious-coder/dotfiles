# Hyprland vs AeroSpace + Sketchybar Feature Matrix

## Scope
- Based only on this repo's active config files.
- Hyprland sources analyzed: `hypr/.config/hypr/hyprland.conf` and its sourced files under `hypr/.config/hypr/configs` and `hypr/.config/hypr/UserConfigs`, plus `hypr/.config/hypr/monitors.conf` and `hypr/.config/hypr/workspaces.conf`.
- AeroSpace sources analyzed: `aerospace/.config/aerospace/aerospace.toml` and scripts under `aerospace/.config/aerospace/scripts`.
- Bar integration analyzed: `waybar/.config/waybar/config` and `sketchybar/.config/sketchybar/sketchybarrc` + plugins.

## Legend
- `☑` = configured/present
- `☐` = not configured/not available
- `◐` = partial approximation

## Gap Checklist (High Impact)
- [x] Scratchpad/special workspace equivalent in AeroSpace workflow
- [ ] Grouped windows/tabs equivalent to Hypr `togglegroup`
- [ ] True pseudotile behavior
- [x] Cmd+drag (or modifier+drag) integrated into AeroSpace workflow
- [ ] Rich window-rule actions parity (size/center/pin/keep_aspect)
- [x] Taskbar/window-list parity in Sketchybar
- [x] Workspace scroll-switch parity in Sketchybar

## Side-by-Side Matrix

| Area | Feature | Hypr (Current Config) | Aero+Sketchybar (Current Config) | Possible: Aero Native | Possible: Aero + Scripts | Needs SIP-Off / Other WM | Notes |
|---|---|---:|---:|---:|---:|---:|---|
| Layout | Dynamic tiling default | ☑ | ☑ | ☑ | ☑ | ☐ | Hypr `layout=dwindle`; Aero `default-root-container-layout='tiles'`. |
| Layout | Dwindle-like split orientation behavior | ☑ | ◐ | ☐ | ☑ | ☐ | Aero uses `auto-split-orientation.sh` approximation (ratio + cursor half). |
| Layout | Preserve split tree/orientation | ☑ | ☑ | ☑ | ☑ | ☐ | Hypr `preserve_split=true`; Aero normalization tuned for preserve-like behavior. |
| Layout | Smart split by cursor triangles | ☐ | ◐ | ☐ | ◐ | ☐ | Hypr capability exists but disabled; Aero has simpler cursor-half heuristic. |
| Layout | Toggle split direction | ☑ | ☑ | ☑ | ☑ | ☐ | Hypr `togglesplit`; Aero `cmd-shift-i = split opposite`. |
| Layout | Pseudotile | ☑ | ☐ | ☐ | ☐ | ☐ | No true pseudotile equivalent configured in AeroSpace. |
| Layout | Master layout mode toggle | ☑ | ☐ | ◐ | ◐ | ☐ | Hypr has Master/Dwindle toggle script; Aero has tiles/accordion but not Master semantics. |
| Layout | Reorganize current layout (flatten + rebalance) | ☐ | ☑ | ☑ | ☑ | ☐ | Aero `cmd-shift-space` + `reorganize-workspace.sh`. |
| Window Ops | Directional focus | ☑ | ☑ | ☑ | ☑ | ☐ | Both have directional focus binds. |
| Window Ops | Directional move | ☑ | ☑ | ☑ | ☑ | ☐ | Both have directional move binds. |
| Window Ops | Directional swap | ☑ | ☑ | ☑ | ☑ | ☐ | Aero swap is bound on `cmd-alt` + arrows/HJKL. |
| Window Ops | Directional resize hotkeys | ☑ | ☑ | ☑ | ☑ | ☐ | Aero resize is bound on `cmd-shift` + arrows/HJKL. |
| Window Ops | Fullscreen | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Window Ops | Fake fullscreen | ☑ | ☐ | ☐ | ☐ | ◐ | Hypr has fake fullscreen bind; Aero has fullscreen/macOS fullscreen but no fake mode parity. |
| Window Ops | Floating toggle | ☑ | ☑ | ☑ | ☑ | ☐ | Aero toggle is bound to `cmd-space` (`layout floating tiling`). |
| Window Ops | Workspace-wide all-float mode | ☑ | ☑ | ☐ | ☑ | ☐ | Implemented via `toggle-all-float-workspace.sh` on `cmd-alt-space`. |
| Window Ops | Pin/always-on-top PiP rules | ☑ | ☐ | ☐ | ◐ | ◐ | Hypr has explicit `pin` + `keep_aspect_ratio`; Aero lacks native equivalent rule action. |
| Window Ops | Per-window visual rules (opacity/no_blur/etc.) | ☑ | ☐ | ☐ | ◐ | ◐ | Hypr has rich rule actions; Aero rule actions are limited. |
| Input | Modifier+mouse move/resize windows | ☑ | ☑ | ☐ | ☑ | ☐ | Implemented with Hammerspoon (`cmd+LMB` move, `cmd+RMB` resize). |
| Input | Cmd+drag window move | ☐ | ☑ | ☐ | ☑ | ☐ | Implemented with Hammerspoon window-drag event taps. |
| Workspaces | Direct workspace selection (numbers) | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured (Hypr 1-10; Aero 1-9 + E). |
| Workspaces | Relative workspace next/prev wrap | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Workspaces | Workspace back-and-forth behavior | ☑ | ☑ | ☑ | ☑ | ☐ | Bound in Aero on `cmd-backslash`. |
| Workspaces | Move window to workspace and follow | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Workspaces | Move window silently to workspace | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Workspaces | Move window to +/- workspace | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Workspaces | Special workspace / scratchpad toggle | ☑ | ☑ | ☐ | ☑ | ☐ | Implemented via dedicated workspace `S` + toggle/send scripts on `cmd-u` / `cmd-shift-u`. |
| Workspaces | Dropdown terminal scratchpad | ☑ | ☑ | ☐ | ☑ | ☐ | Implemented via `toggle-dropdown-terminal.sh` on `cmd-shift-enter`. |
| Workspaces | Move current workspace to next monitor | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured (Hypr via script bind; Aero native command bind). |
| Workspaces | Static workspace-to-monitor assignment rules | ☐ | ☐ | ☑ | ☑ | ☐ | Supported by both ecosystems but not configured in current files. |
| Workspaces | Scroll-to-switch workspaces (global) | ☑ | ☐ | ☐ | ☑ | ☐ | Aero needs external event tooling for global scroll bindings. |
| Grouping | Group/tab windows | ☑ | ☐ | ☐ | ☐ | ☐ | Hypr `togglegroup` exists; no direct Aero equivalent configured. |
| Grouping | Cycle windows within group | ☑ | ☐ | ☐ | ☐ | ☐ | Hypr `changegroupactive`; no direct Aero group construct. |
| Rules | App tagging abstraction | ☑ | ☐ | ☐ | ☑ | ☐ | Hypr uses `tag +...`; Aero uses explicit app-id mapping instead. |
| Rules | App-based workspace routing | ☑ | ☑ | ☑ | ☑ | ☐ | Both configured. |
| Rules | Silent app routing on spawn | ☑ | ☑ | ☑ | ☑ | ☐ | Effectively present in both setups. |
| Rules | Title/dialog float + size + center rules | ☑ | ◐ | ◐ | ◐ | ☐ | Implemented approximation via `apply-focused-window-rules.sh` + Hammerspoon window rules. |
| Rules | Game auto-fullscreen rule | ☑ | ☐ | ☐ | ◐ | ☐ | Aero on-window rule actions are limited; workaround requires custom script logic. |
| Rules | Idle inhibit on fullscreen | ☑ | ☐ | ☐ | ☐ | ☐ | Hypr feature not available in AeroSpace/macOS WM layer directly. |
| Rules | Swallow windows | ☐ | ☐ | ☐ | ☐ | ☐ | Feature disabled in Hypr config; no Aero equivalent configured. |
| Startup | Startup apps launched to target workspaces | ☑ | ◐ | ☐ | ☑ | ☐ | Hypr explicit `exec-once` workspace launches; Aero currently remaps/reroutes after start. |
| Bar | Workspace module integrated with WM | ☑ | ☑ | ☐ | ☑ | ☐ | Waybar Hypr module active; Sketchybar plugin uses Aero CLI. |
| Bar | Per-monitor workspace filtering | ☑ | ☑ | ☐ | ☑ | ☐ | Waybar `all-outputs=false`; Sketchybar `workspaces.sh` maps display IDs. |
| Bar | Active/visible workspace highlighting | ☑ | ☑ | ☐ | ☑ | ☐ | Both setups highlight active/visible workspaces. |
| Bar | Front app indicator | ◐ | ☑ | ☐ | ☑ | ☐ | Hypr setup shows taskbar/window context; Aero setup has explicit front-app label plugin. |
| Bar | Taskbar/window list | ☑ | ◐ | ☐ | ☑ | ☐ | Implemented as focused-workspace `windowlist` item via `tasklist.sh` (summary style, not full icons/buttons parity). |
| Bar | Workspace click-to-switch | ☑ | ☑ | ☐ | ☑ | ☐ | Both bars support click switching. |
| Bar | Workspace scroll-switch in bar module | ☑ | ☑ | ☐ | ☑ | ☐ | Implemented via `workspace_item.sh` handling `mouse.scrolled`. |
| Bar | Update model (event-driven vs polling) | ☑ | ◐ | ☐ | ☑ | ☐ | Waybar module is WM-integrated; Sketchybar workspace updater uses mixed events + polling (`update_freq=1`). |
| Bar | Multi-display notch-aware placement | ☐ | ☑ | ☐ | ☑ | ☐ | Sketchybar has built-in-display clock/battery notch-aware placement logic. |
| UX | Instant transitions / animations disabled | ☑ | ☑ | ☑ | ☑ | ☐ | Hypr animations disabled; Aero + macOS shortcut cleanup targets instant feel. |

## Priority Gap Notes
1. Grouping/tabbing parity is the biggest structural gap (Hypr `togglegroup` has no true Aero equivalent).
2. Pseudotile parity is unavailable as a direct Aero feature.
3. Rich window-rule parity (pin/keep_aspect/idle_inhibit/game fullscreen semantics) remains limited.
4. Taskbar parity is now present as a summary list, but still not full icon/button parity with Waybar taskbar.
5. Global mod+scroll workspace switching parity is still partial (implemented in Sketchybar workspace items).
