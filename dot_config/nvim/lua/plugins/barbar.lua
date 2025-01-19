-- Test
return {
  "romgrk/barbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "lewis6991/gitsigns.nvim",
  },
  config = function()
    require("barbar").setup({
      animation = true,
      auto_hide = false,
      tabpages = true,
      clickable = true,
      icons = {
        buffer_index = true,
        filetype = { enabled = true },
        separator = { left = "▎", right = "▎" },
      },
      no_name_title = "New Buffer",
    })

    local opts = { noremap = true, silent = true }

    -- Buffer Navigation
    vim.keymap.set("n", "<leader>h", "<Cmd>BufferPrevious<CR>", opts)
    vim.keymap.set("n", "<leader>l", "<Cmd>BufferNext<CR>", opts)

    -- Direct Buffer Selection (1-9)
    for i = 1, 9 do
      vim.keymap.set("n", "<leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", opts)
    end

    -- Buffer Management
    vim.keymap.set("n", "<leader>x", "<Cmd>BufferDelete<CR>", opts)
    vim.keymap.set("n", "<leader>p", "<Cmd>BufferPin<CR>", opts)
    vim.keymap.set("n", "<leader>L", "<Cmd>BufferLast<CR>", opts)

    -- Buffer Reordering
    vim.keymap.set("n", "<A-h>", "<Cmd>BufferMovePrevious<CR>", opts)
    vim.keymap.set("n", "<A-l>", "<Cmd>BufferMoveNext<CR>", opts)
  end,
}
