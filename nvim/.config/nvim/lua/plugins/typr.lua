-- ┌─────────────────────────────────────────────────────────────┐
-- │ Typr - Typing Practice (Optional)                           │
-- │ Purpose: Practice typing speed and accuracy                 │
-- │ Usage: :Typr to start, :TyprStats to view statistics        │
-- │ Note: Purely optional, can be safely removed                │
-- └─────────────────────────────────────────────────────────────┘

return {
    "nvzone/typr",
    dependencies = "nvzone/volt",
    cmd = { "Typr", "TyprStats" }, -- Only loads when commands are used
    opts = {},
}
