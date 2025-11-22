return {
  "pocco81/auto-save.nvim",
  event = { "BufLeave", "FocusLost" },
  opts = {
    enabled = true,
    execution_message = { enabled = false },
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = {},
      cancel_defered_save = {},
    },
    write_all_buffers = false,
    debounce_delay = 135,
  },
}
