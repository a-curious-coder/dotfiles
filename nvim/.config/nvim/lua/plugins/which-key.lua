return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = function()
    local wk = require("which-key")
    wk.setup({
      plugins = {
        marks = true,
        registers = true,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
      },
      window = {
        border = "single",
        position = "bottom",
      },
      layout = {
        spacing = 6,
        align = "center",
      },
    })

    -- Register key groups
    wk.register({
      ["<leader>"] = {
        f = { name = "Find/Files" },
        g = { name = "Git" },
        b = { name = "Buffers" },
        w = { name = "Workspace" },
        t = { name = "Tests" },
        d = { name = "Debug" },
        c = { name = "Code" },
        u = { name = "UI" },
      },
    })
  end
}