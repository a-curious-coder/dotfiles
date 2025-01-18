return {
  'romgrk/barbar.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- Optional: file icons
    'lewis6991/gitsigns.nvim',     -- Optional: git status integration
  },
  opts = {
    -- Productivity-focused configuration
    animation = true,        -- Smooth transitions
    auto_hide = false,       -- Always show bufferline
    clickable = true,        -- Enable mouse interactions
    focus_on_close = 'left', -- Predictable buffer navigation

    -- Minimalist appearance
    maximum_padding = 1,
    minimum_padding = 1,
    maximum_length = 30, -- Reasonable buffer name length

    -- User-friendly features
    icons = {
      preset = 'default',  -- Clean, standard icon set
      buffer_index = true, -- Show buffer numbers
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true },
        [vim.diagnostic.severity.WARN] = { enabled = true },
      },
    },

    -- Semantic buffer selection
    semantic_letters = true,
    letters = 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP',

    -- Sorting and organization
    sort = {
      ignore_case = true, -- Case-insensitive sorting
    },

    -- Sidebar integration
    sidebar_filetypes = {
      NvimTree = true,
      undotree = { text = 'Undo', align = 'left' },
    }
  },

  -- Key mappings for efficient navigation
  config = function(_, opts)
    require('barbar').setup(opts)

    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    -- Buffer navigation
    map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', opts)
    map('n', '<A-.>', '<Cmd>BufferNext<CR>', opts)

    -- Buffer management
    map('n', '<A-c>', '<Cmd>BufferClose<CR>', opts)
    map('n', '<A-p>', '<Cmd>BufferPin<CR>', opts)

    -- Quick buffer selection
    map('n', '<C-p>', '<Cmd>BufferPick<CR>', opts)
  end
}
