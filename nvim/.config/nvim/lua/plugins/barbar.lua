-- ~/.config/nvim/lua/plugins/barbar.lua (or wherever you define plugins)
return {
  "romgrk/barbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- Recommended for icons
    -- 'lewis6991/gitsigns.nvim' -- NOTE: Not a direct Barbar dependency, but Barbar *will* show git status if gitsigns is installed & configured.
  },
  init = function()
    -- Set barbar's internal mappings before it loads if you want default keymaps disabled
    -- vim.g.barbar_auto_setup = false -- Uncomment if you DON'T want ANY default keymaps
  end,
  opts = {
    -- Configure BarBar as you like
    animation = true, -- Subtle animation enhances UX slightly
    auto_hide = false, -- Keep it visible (as you had)
    tabpages = true, -- Integrate with native tab pages
    clickable = true, -- Essential for mouse users
    -- Exclude certain filetypes (e.g., terminals, NvimTree)
    exclude_filetypes = { 'NvimTree', 'toggleterm', 'lazyterm' },
    -- Exclude buffers matching patterns
    -- exclude_patterns = { '*/.git/*', '*/undodir/*' },

    icons = {
      -- Configure icons
      -- Requires a Nerd Font
      button = '', -- Add a clickable close button (recommend '' or '')
      buffer_index = true, -- Show buffer index
      buffer_number = false, -- Keep buffer number hidden (as you had)
      diagnostics = {
        [vim.diagnostic.severity.ERROR] = { enabled = true, icon = 'ﬀ' },
        [vim.diagnostic.severity.WARN] = { enabled = true, icon = '' },
        [vim.diagnostic.severity.INFO] = { enabled = true, icon = '' },
        [vim.diagnostic.severity.HINT] = { enabled = true, icon = '' },
      },
      filetype = {
        enabled = true,
        custom_colors = false,
      },
      git = {
        changed = { enabled = true, icon = '+' }, -- Requires gitsigns.nvim
        added = { enabled = true, icon = '+' },   -- Requires gitsigns.nvim
        deleted = { enabled = true, icon = '-' }, -- Requires gitsigns.nvim
      },
      separator = { left = '▎', right = '▎' }, -- Keep your separator
      -- Make pinned buffers more obvious
      pinned = { button = '', filename = true },
      modified = { button = '●' },
    },

    -- Jump to buffer using specified letters. Semantic picks based on file name.
    semantic_letters = true,
    letters = "asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM", -- Use standard keys

    -- Set buffer title when buffer is unnamed
    no_name_title = "Untitled",

    -- Set the maximum buffer name length.
    maximum_padding = 4,
    maximum_length = 30,

    -- Sort buffers by certain criteria
    -- sort_by = 'index' | 'filename' | 'filetype' | 'full_path' | 'modified' | 'pinned' | function
    sort_by = 'index', -- Default sorting is usually fine

  },
  version = '^1.0.0', -- optional: always fetch a stable version
  config = function(_, opts)
    require('barbar').setup(opts)

    -- --- Custom Keymaps for Productivity ---
    local map = vim.keymap.set
    local opts_noremap_silent = { noremap = true, silent = true }

    -- Navigate buffers
    map('n', '<leader>bp', '<Cmd>BufferPrevious<CR>', opts_noremap_silent) -- Go to Previous Buffer
    map('n', '<leader>bn', '<Cmd>BufferNext<CR>', opts_noremap_silent)     -- Go to Next Buffer
    map('n', '<leader>bf', '<Cmd>BufferFirst<CR>', opts_noremap_silent)    -- Go to First Buffer
    map('n', '<leader>bl', '<Cmd>BufferLast<CR>', opts_noremap_silent)     -- Go to Last Buffer (you had this)

    -- Select buffers by index (keep your mapping)
    for i = 1, 9 do
      map('n', '<leader>' .. i, '<Cmd>BufferGoto ' .. i .. '<CR>', opts_noremap_silent)
    end
    -- Select buffer by letter (VERY productive)
    map('n', '<leader>bb', '<Cmd>BufferPick<CR>', opts_noremap_silent)      -- Pick Buffer via letters

    -- Close buffers
    -- NOTE: <leader>x often conflicts with save+quit (:x). Using <leader>bc is clearer.
    map('n', '<leader>bc', '<Cmd>BufferClose<CR>', opts_noremap_silent)     -- Close Current Buffer (consider BufferClose vs BufferDelete)
    map('n', '<leader>bx', '<Cmd>BufferPickDelete<CR>', opts_noremap_silent)-- Pick Buffer to Close

    -- Pin/unpin buffer (keep your mapping)
    map('n', '<A-p>', '<Cmd>BufferPin<CR>', opts_noremap_silent)            -- Pin/Unpin Current Buffer

    -- Move buffer position (using Alt + h/l is more Vim-like than < / >)
    map('n', '<A-h>', '<Cmd>BufferMovePrevious<CR>', opts_noremap_silent) -- Move current buffer left
    map('n', '<A-l>', '<Cmd>BufferMoveNext<CR>', opts_noremap_silent)     -- Move current buffer right

    -- Optional: Toggle visibility (less needed if auto_hide=false, but can be useful)
    -- map('n', '<leader>bT', '<Cmd>BufferToggle<CR>', opts_noremap_silent)

    -- Optional: Sort buffers
    -- map('n', '<Space>bsf', '<Cmd>BufferOrderBy FileName<CR>', opts_noremap_silent)
    -- map('n', '<Space>bse', '<Cmd>BufferOrderBy Extension<CR>', opts_noremap_silent)
    -- map('n', '<Space>bsd', '<Cmd>BufferOrderBy Directory<CR>', opts_noremap_silent)

  end,
}
