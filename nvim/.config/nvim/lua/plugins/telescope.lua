return {
  {
    "nvim-telescope/telescope-ui-select.nvim",
    "smartpde/telescope-recent-files",
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make", -- For better performance
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
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

      -- Enhanced keymaps for productivity
      -- File navigation
      vim.keymap.set("n", "<leader>pf", function()
        builtin.find_files({ hidden = true, no_ignore = true })
      end, { desc = "Find all files (including hidden)" })

      vim.keymap.set("n", "<leader>pg", builtin.git_files, { desc = "Find files tracked by git" })
      vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find files tracked by git" })

      -- Buffer management
      vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "Find buffers" })

      -- Text search
      vim.keymap.set("n", "<leader>ps", function()
        builtin.live_grep({ additional_args = { "--hidden" } })
      end, { desc = "Live grep (including hidden files)" })

      vim.keymap.set("n", "<leader>pw", function()
        builtin.grep_string({ search = vim.fn.expand("<cword>"), additional_args = { "--hidden" } })
      end, { desc = "Grep current word (including hidden files)" })

      vim.keymap.set("n", "<leader>pW", function()
        builtin.grep_string({ search = vim.fn.expand("<cWORD>"), additional_args = { "--hidden" } })
      end, { desc = "Grep current WORD (including hidden files)" })

      vim.keymap.set("n", "<leader>pg", function()
        builtin.grep_string({ search = vim.fn.input("Grep > "), additional_args = { "--hidden" } })
      end, { desc = "Grep with input (including hidden files)" })

      -- Recent files
      vim.keymap.set("n", "<leader><leader>", function()
        require('telescope').extensions.recent_files.pick()
      end, { desc = "Recent files", noremap = true, silent = true })

      -- Help and documentation
      vim.keymap.set("n", "<leader>vh", builtin.help_tags, { desc = "Help tags" })

      -- Additional useful pickers
      vim.keymap.set("n", "<leader>pc", builtin.commands, { desc = "Commands" })
      vim.keymap.set("n", "<leader>pk", builtin.keymaps, { desc = "Keymaps" })
      vim.keymap.set("n", "<leader>pr", builtin.resume, { desc = "Resume last picker" })
      vim.keymap.set("n", "<leader>po", builtin.oldfiles, { desc = "Recently opened files" })
    end,
  },
}

