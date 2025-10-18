return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  version = "^3.0.0", -- Ensure we use v3.x which is compatible with Neovim 0.11+
  
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,

  config = function()
    local wk = require("which-key")

    wk.setup({
      preset = "modern", -- Use modern preset for Neovim 0.11+
      
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
      },

      -- Icons configuration
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
      },

      show_help = true,
    })

    -- Register mappings with the new format using wk.add (v3.x API)
    wk.add({
      { "<leader>b", group = "Buffers" },
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Debug" },
      { "<leader>f", group = "Find/Files" },
      { "<leader>fp", group = "Projects" },
      { "<leader>fp<space>", group = "Find projects" },
      { "<leader>g", group = "Git" },
      { "<leader>t", group = "Tests" },
      { "<leader>u", group = "UI" },
      { "<leader>w", group = "Workspace" },
      { "<leader>?", desc = "Show all keybindings" },
      { "g", group = "Go/LSP" },
      { "g%", group = "Cycle results" },
      { "gO", group = "Document symbols" },
      { "gc", group = "Comments" },
      { "gcc", group = "Toggle line" },
      { "gr", group = "References" },
      { "gra", group = "Code action" },
      { "gri", group = "Implementation" },
      { "grn", group = "Rename" },
      { "grr", group = "Find references" },
      { "gx", group = "Open under cursor" },
    })
    
    -- Keybinding to view all keymaps
    vim.keymap.set("n", "<leader>?", function()
      require("which-key").show({ global = true })
    end, { desc = "Show all keybindings" })
  end
}
