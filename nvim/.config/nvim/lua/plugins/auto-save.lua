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
        trigger_events = { -- See :h events
            immediate_save = { "BufLeave", "FocusLost" }, -- vim events that trigger an immediate save
            defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after waiting for `debounce_delay`)
            cancel_defered_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
        },
        write_all_buffers = false, -- write all buffers when the current one meets `condition`
        debounce_delay = 1000, -- delay after which a pending save is executed
    }
} 