return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      separator_style = "thin",
      always_show_bufferline = false,
    },
  },
  config = function(_, opts)
    require("bufferline").setup(opts)

    vim.keymap.set("n", "[b", "<cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
    vim.keymap.set("n", "]b", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

    local function goto_visible_buffer(index)
      local state = require("bufferline.state")
      if index < 1 or index > #state.visible_components then
        return
      end
      vim.cmd("BufferLineGoToBuffer " .. index)
    end

    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, function()
        goto_visible_buffer(i)
      end, {
        desc = "Go to buffer " .. i,
      })
    end
  end,
}
