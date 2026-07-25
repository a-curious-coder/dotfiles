#!/usr/bin/env python3
"""Transient mic on/off popup anchored to the text caret, macOS-dictation
style. Falls back to the mouse cursor when the focused app doesn't expose a
caret position over AT-SPI (e.g. terminals, or nothing text-focused).

Usage: mic-indicator.py on|off
"""

from __future__ import annotations

import json
import subprocess
import sys
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("Atspi", "2.0")
from gi.repository import Atspi, Gtk, GtkLayerShell, GLib  # noqa: E402

ICON_ON = ""  # nf-fa-microphone
ICON_OFF = ""  # nf-fa-microphone_slash
DURATION_MS = 1100
CURSOR_OFFSET = 18

ATSPI_TIMEOUT_MS = 250
ATSPI_SEARCH_BUDGET_S = 0.25
ATSPI_MAX_DEPTH = 12

CSS = b"""
window {
    background-color: rgba(10, 110, 255, 0.92);
    border-radius: 999px;
}
label {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 22px;
    color: #ffffff;
    padding: 10px 16px;
    min-width: 24px;
}
label.mic-off {
    padding-left: 10px;
    padding-right: 22px;
}
"""


def cursor_pos() -> tuple[int, int]:
    out = subprocess.run(
        ["hyprctl", "cursorpos"], capture_output=True, text=True, check=True
    ).stdout
    x_str, y_str = out.strip().split(",")
    return int(x_str.strip()), int(y_str.strip())


def _active_window_pid() -> int | None:
    try:
        out = subprocess.run(
            ["hyprctl", "activewindow", "-j"],
            capture_output=True,
            text=True,
            check=True,
            timeout=1.0,
        ).stdout
        pid = json.loads(out).get("pid")
        return int(pid) if pid else None
    except Exception:
        return None


def _find_focused(accessible, deadline: float, depth: int = 0):
    if accessible is None or depth > ATSPI_MAX_DEPTH or time.monotonic() > deadline:
        return None
    try:
        if accessible.get_state_set().contains(Atspi.StateType.FOCUSED):
            return accessible
    except Exception:
        pass
    try:
        count = accessible.get_child_count()
    except Exception:
        return None
    for i in range(count):
        if time.monotonic() > deadline:
            return None
        try:
            child = accessible.get_child_at_index(i)
        except Exception:
            continue
        found = _find_focused(child, deadline, depth + 1)
        if found is not None:
            return found
    return None


def _caret_screen_pos() -> tuple[int, int] | None:
    """Caret position of the focused text field in the active window, via
    AT-SPI. None if unavailable: terminals and many apps don't expose a text
    caret this way, and nothing may be text-focused at all."""
    pid = _active_window_pid()
    if pid is None:
        return None

    try:
        Atspi.set_timeout(ATSPI_TIMEOUT_MS, 0)
        desktop = Atspi.get_desktop(0)
        app = None
        for i in range(desktop.get_child_count()):
            candidate = desktop.get_child_at_index(i)
            try:
                if candidate.get_process_id() == pid:
                    app = candidate
                    break
            except Exception:
                continue
        if app is None:
            return None

        found = _find_focused(app, time.monotonic() + ATSPI_SEARCH_BUDGET_S)
        if found is None:
            return None

        caret = found.get_caret_offset()
        extents = found.get_character_extents(caret, Atspi.CoordType.SCREEN)
        if extents.width <= 0 and extents.height <= 0:
            return None
        return int(extents.x), int(extents.y + extents.height)
    except Exception:
        return None


def main() -> int:
    on = len(sys.argv) > 1 and sys.argv[1] == "on"
    x, y = _caret_screen_pos() or cursor_pos()

    win = Gtk.Window(type=Gtk.WindowType.POPUP)
    screen = win.get_screen()
    visual = screen.get_rgba_visual()
    if visual is not None:
        win.set_visual(visual)
    win.set_decorated(False)

    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.NONE)
    GtkLayerShell.set_exclusive_zone(win, -1)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.LEFT, x + CURSOR_OFFSET)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, y + CURSOR_OFFSET)

    label = Gtk.Label(label=ICON_ON if on else ICON_OFF)
    label.set_xalign(0.5)
    label.set_yalign(0.5)
    if not on:
        label.get_style_context().add_class("mic-off")
    win.add(label)

    css_provider = Gtk.CssProvider()
    css_provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    win.show_all()
    GLib.timeout_add(DURATION_MS, Gtk.main_quit)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
