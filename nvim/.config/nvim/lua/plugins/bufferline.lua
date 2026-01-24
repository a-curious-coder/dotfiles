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

    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", {
        desc = "Go to buffer " .. i,
      })
    end
  end,
}
