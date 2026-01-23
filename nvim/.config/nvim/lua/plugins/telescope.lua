-- ┌─────────────────────────────────────────────────────────────┐
-- │ Telescope - Fuzzy Finder                                    │
-- │ Purpose: Fast file/text searching and navigation            │
-- │ Dependencies: ripgrep (for grep), fd (optional for speed)    │
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

      local fd_cmd = nil
      local fd_bin = nil

      if vim.fn.executable("fd") == 1 then
        fd_bin = "fd"
      elseif vim.fn.executable("fdfind") == 1 then
        fd_bin = "fdfind"
      end

      if fd_bin then
        fd_cmd = { fd_bin, "--type", "f", "--hidden", "--exclude", ".git" }
      else
        if not vim.g._telescope_fd_notice then
          vim.g._telescope_fd_notice = true
          vim.schedule(function()
            vim.notify("Telescope: install `fd` for faster file searching.", vim.log.levels.INFO)
          end)
        end
      end

      if vim.fn.executable("rg") == 0 then
        if not vim.g._telescope_rg_notice then
          vim.g._telescope_rg_notice = true
          vim.schedule(function()
            vim.notify("Telescope: install `rg` (ripgrep) for live grep.", vim.log.levels.WARN)
          end)
        end
      end

      local defaults = {
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
      }

      if fd_cmd then
        defaults.find_command = fd_cmd
      end

      telescope.setup({
        defaults = defaults,
        pickers = {
          find_files = {
            theme = "dropdown",
            hidden = true,    -- Show hidden files
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
        builtin.find_files({ hidden = true })
      end, { desc = "Find files" })

      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })

      vim.keymap.set("n", "<leader>fs", function()
        builtin.live_grep({ additional_args = { "--hidden" } })
      end, { desc = "Live grep" })

      vim.keymap.set("n", "<leader><leader>", function()
        require("telescope").extensions.recent_files.pick()
      end, { desc = "Recent files" })
    end,
  },
}
