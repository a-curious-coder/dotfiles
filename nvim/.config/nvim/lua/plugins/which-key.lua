return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  version = "^3.0.0",

  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,

  config = function()
    local wk = require("which-key")

    wk.setup({
      preset = "modern",
      plugins = {
        marks = true,
        registers = true,
        spelling = { enabled = true, suggestions = 20 },
      },
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },
      show_help = true,
    })

    -- Register key groups for discoverability
    wk.add({
      { "<leader>b", group = "Buffers" },
      { "<leader>c", group = "Code" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>u", group = "UI Toggles" },
      { "g", group = "Go/LSP" },
      { "gc", group = "Comments" },
      { "z", group = "Folds" },
    })

    -- Show all keybindings
    vim.keymap.set("n", "<leader>?", function()
      require("which-key").show({ global = true })
    end, { desc = "Show all keybindings" })
  end,
}
