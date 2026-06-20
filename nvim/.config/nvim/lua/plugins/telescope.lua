return {
  { "nvim-telescope/telescope-ui-select.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")

      local fd_bin = vim.fn.executable("fd") == 1 and "fd"
        or vim.fn.executable("fdfind") == 1 and "fdfind"
        or nil

      telescope.setup({
        defaults = {
          find_command = fd_bin
            and { fd_bin, "--type", "f", "--hidden", "--exclude", ".git" }
            or nil,
          file_ignore_patterns = { "%.git/", "node_modules/", "%.DS_Store" },
          path_display = { "filename_first" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
          },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
            n = { ["q"] = actions.close },
          },
        },
        pickers = {
          find_files = { theme = "dropdown", hidden = true },
          live_grep = { additional_args = { "--hidden" } },
          grep_string = { additional_args = { "--hidden" } },
          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            theme = "dropdown",
            mappings = {
              i = { ["<C-d>"] = actions.delete_buffer },
              n = { ["dd"] = actions.delete_buffer },
            },
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      pcall(telescope.load_extension, "ui-select")
      pcall(telescope.load_extension, "fzf")

      local function project_root()
        local buf = vim.api.nvim_buf_get_name(0)
        local dir = buf ~= "" and vim.fn.fnamemodify(buf, ":p:h") or vim.fn.getcwd()
        local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
        if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then return out[1] end
        return vim.fn.getcwd()
      end

      local function is_repo_scope()
        if vim.g.telescope_scope_mode == nil then vim.g.telescope_scope_mode = "repo" end
        return vim.g.telescope_scope_mode == "repo"
      end

      local function scope_opts()
        return { cwd = is_repo_scope() and project_root() or nil }
      end

      local function toggle_scope()
        vim.g.telescope_scope_mode = is_repo_scope() and "global" or "repo"
        vim.notify("Telescope scope: " .. vim.g.telescope_scope_mode, vim.log.levels.INFO)
      end

      vim.keymap.set("n", "<leader>ff", function()
        local opts = scope_opts()
        local ok = pcall(builtin.git_files, vim.tbl_extend("force", opts, { show_untracked = true }))
        if not ok then builtin.find_files(vim.tbl_extend("force", opts, { hidden = true })) end
      end, { desc = "Find files" })

      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })

      vim.keymap.set("n", "<leader>fs", function()
        builtin.live_grep(vim.tbl_extend("force", scope_opts(), { additional_args = { "--hidden" } }))
      end, { desc = "Live grep" })

      vim.keymap.set("n", "<leader>fo", function()
        builtin.live_grep(vim.tbl_extend("force", scope_opts(), {
          grep_open_files = true,
          prompt_title = "Live grep (open files)",
          additional_args = { "--hidden" },
        }))
      end, { desc = "Live grep open files" })

      vim.keymap.set("n", "<leader>?", builtin.keymaps, { desc = "Find keymaps" })

      vim.keymap.set("n", "<leader>fr", function()
        builtin.oldfiles(vim.tbl_extend("force", scope_opts(), { cwd_only = is_repo_scope() }))
      end, { desc = "Recent files" })

      vim.keymap.set("n", "<leader>fT", toggle_scope, { desc = "Toggle find scope (repo/global)" })
    end,
  },
}
