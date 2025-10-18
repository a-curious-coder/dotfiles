-- ┌─────────────────────────────────────────────────────────────┐
-- │ Auto-Save                                                   │
-- │ Purpose: Automatically save files on changes                │
-- │ Trigger: InsertLeave, TextChanged, BufLeave, FocusLost      │
-- └─────────────────────────────────────────────────────────────┘

return {
    "pocco81/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
        enabled = true,
        execution_message = {
            message = function()
                return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
            end,
        },
        trigger_events = {
            immediate_save = { "BufLeave", "FocusLost" },
            defer_save = { "InsertLeave", "TextChanged" },
            cancel_defered_save = { "InsertEnter" },
        },
        write_all_buffers = false,
        debounce_delay = 1000, -- Wait 1 second before saving
    }
} 