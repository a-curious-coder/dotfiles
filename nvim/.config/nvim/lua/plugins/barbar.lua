return {
  "romgrk/barbar.nvim",
  version = "^1.0.0",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    animation = true,
    auto_hide = false,
    tabpages = true,
    clickable = true,
    exclude_filetypes = { "NvimTree", "toggleterm", "lazyterm" },

    icons = {
      button = "",
      buffer_index = true,
      buffer_number = false,
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true, icon = "ﬀ" },
        [vim.diagnostic.severity.WARN] = { enabled = true, icon = "" },
        [vim.diagnostic.severity.INFO] = { enabled = true, icon = "" },
        [vim.diagnostic.severity.HINT] = { enabled = true, icon = "" },
      },
      filetype = { enabled = true, custom_colors = false },
      git = {
        changed = { enabled = true, icon = "+" },
        added = { enabled = true, icon = "+" },
        deleted = { enabled = true, icon = "-" },
      },
      separator = { left = "▎", right = "▎" },
      pinned = { button = "", filename = true },
      modified = { button = "●" },
    },

    semantic_letters = true,
    letters = "asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM",
    no_name_title = "Untitled",
    maximum_padding = 4,
    maximum_length = 30,
    sort_by = "index",
  },

  config = function(_, opts)
    require("barbar").setup(opts)

    local map = vim.keymap.set
    local o = { noremap = true, silent = true }

    -- Navigation
    map("n", "<leader>bp", "<Cmd>BufferPrevious<CR>", o)
    map("n", "<leader>bn", "<Cmd>BufferNext<CR>", o)
    map("n", "<leader>bf", "<Cmd>BufferFirst<CR>", o)
    map("n", "<leader>bl", "<Cmd>BufferLast<CR>", o)

    -- Jump to buffer by index
    for i = 1, 9 do
      map("n", "<leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", o)
    end

    -- Buffer actions
    map("n", "<leader>bb", "<Cmd>BufferPick<CR>", o)
    map("n", "<leader>bc", "<Cmd>BufferClose<CR>", o)
    map("n", "<leader>bx", "<Cmd>BufferPickDelete<CR>", o)
    map("n", "<A-p>", "<Cmd>BufferPin<CR>", o)
    map("n", "<A-h>", "<Cmd>BufferMovePrevious<CR>", o)
    map("n", "<A-l>", "<Cmd>BufferMoveNext<CR>", o)
  end,
}
