-- ┌─────────────────────────────────────────────────────────────┐
-- │ Telescope - Fuzzy Finder                                    │
-- │ Purpose: Fast file/text searching and navigation            │
-- │ Dependencies: ripgrep (for grep), fd (for file search)      │
-- └─────────────────────────────────────────────────────────────┘

return {
  -- Extension: Better UI for selections
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
  
  -- Extension: Recent files tracking
  {
    "smartpde/telescope-recent-files",
  },
  
  -- Extension: FZF native for better performance
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
  
  -- Main Telescope plugin
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "%.git/", -- Still ignore .git directory to avoid clutter
            "node_modules/",
            "%.DS_Store"
          },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close, -- Close with single Escape
              ["<C-u>"] = false,         -- Disable default scroll up to allow history navigation
              ["<C-d>"] = false,         -- Disable default scroll down
            },
            n = {
              ["q"] = actions.close, -- Close with q in normal mode
            },
          },
          path_display = { "truncate" },  -- Better path display
          sorting_strategy = "ascending", -- Show results from top to bottom
          layout_config = {
            horizontal = {
              prompt_position = "top", -- Prompt at the top
              preview_width = 0.55,    -- Wider preview
            },
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
            hidden = true,    -- Show hidden files
            no_ignore = true, -- Don't respect .gitignore
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" } -- Show hidden files in grep results
            end,
          },
          grep_string = {
            additional_args = function()
              return { "--hidden" } -- Show hidden files in grep_string
            end,
          },
          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            theme = "dropdown",
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      -- Load extensions
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension("fzf") -- Much faster fuzzy finding

      -- Keymaps: <leader>f = find/search operations
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({ hidden = true, no_ignore = true })
      end, { desc = "Find files (all)" })

      vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Find files (git)" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })

      vim.keymap.set("n", "<leader>fs", function()
        builtin.live_grep({ additional_args = { "--hidden" } })
      end, { desc = "Live grep" })

      vim.keymap.set("n", "<leader>fw", function()
        builtin.grep_string({ search = vim.fn.expand("<cword>"), additional_args = { "--hidden" } })
      end, { desc = "Search word under cursor" })

      vim.keymap.set("n", "<leader>fW", function()
        builtin.grep_string({ search = vim.fn.expand("<cWORD>"), additional_args = { "--hidden" } })
      end, { desc = "Search WORD under cursor" })

      vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "Resume last search" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
      vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })

      vim.keymap.set("n", "<leader><leader>", function()
        require('telescope').extensions.recent_files.pick()
      end, { desc = "Recent files" })
    end,
  },
}

