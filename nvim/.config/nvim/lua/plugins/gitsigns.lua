return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 300,
      ignore_whitespace = false,
    },
  },
  config = function(_, opts)
    local gitsigns = require("gitsigns")
    gitsigns.setup(opts)

    vim.keymap.set("n", "<leader>gb", function()
      gitsigns.blame_line({ full = true })
    end, { desc = "Blame line" })

    vim.keymap.set("n", "<leader>gB", function()
      gitsigns.toggle_current_line_blame()
    end, { desc = "Toggle line blame" })
  end,
}
