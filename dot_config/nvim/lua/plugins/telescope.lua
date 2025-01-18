return {
	{
		"nvim-telescope/telescope-ui-select.nvim",
		"smartpde/telescope-recent-files",
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5", -- Use the latest stable version
		dependencies = {
			"nvim-lua/plenary.nvim", -- Required dependency
			"nvim-tree/nvim-web-devicons", -- Optional, for file icons
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous, -- move to prev result
							["<C-j>"] = actions.move_selection_next, -- move to next result
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
				pickers = {
					find_files = {
						theme = "dropdown", -- Use dropdown theme for find_files
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})

			-- Load extensions
			telescope.load_extension("ui-select")
			telescope.load_extension("recent_files")

			-- Keymaps
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find files tracked by git" })

			vim.keymap.set("n", "<leader>pws", function()
				local word = vim.fn.expand("<cword>")
				builtin.grep_string({ search = word })
			end, { desc = "Find files tracked by git" })

			vim.keymap.set("n", "<leader>pWs", function()
				local word = vim.fn.expand("<cWORD>")
				builtin.grep_string({ search = word })
			end, { desc = "Find files tracked by git" })

			vim.keymap.set("n", "<leader>ps", function()
				builtin.grep_string({ search = vim.fn.input("Grep > ") })
			end)

			vim.api.nvim_set_keymap(
				"n",
				"<Leader><Leader>",
				[[<cmd>lua require('telescope').extensions.recent_files.pick()<CR>]],
				{ noremap = true, silent = true }
			)

			vim.keymap.set("n", "<leader>vh", builtin.help_tags, { desc = "Help tags" })
		end,
	},
}
