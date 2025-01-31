return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		-- Global options
		close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = true,

		-- Filesystem options
		filesystem = {
			filtered_items = {
				visible = true, -- Show hidden files
				hide_dotfiles = false,
				hide_gitignored = false,
			},
			follow_current_file = true, -- Highlight the current file in the tree
			use_libuv_file_watcher = true, -- Use more efficient file watching
		},

		-- Window options
		window = {
			position = "right", -- Place Neo-tree on the right side
			width = 40, -- Set the width of the Neo-tree window
			mappings = {
				["<space>"] = "toggle_node",
				["<2-LeftMouse>"] = "open",
				["<cr>"] = "open",
				["S"] = "open_split",
				["s"] = "open_vsplit",
				["C"] = "close_node",
				["z"] = "close_all_nodes",
				["R"] = "refresh",
			},
		},

		-- Default component configurations
		default_component_configs = {
			indent = {
				with_expanders = true, -- Use expander icons for folders
				expander_collapsed = "",
				expander_expanded = "",
				expander_highlight = "NeoTreeExpander",
			},
		},
	},
	config = function()
		-- Keymaps for opening Neo-tree
		vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal right<CR>", { desc = "Open Neo-tree file explorer" })
		vim.keymap.set(
			"n",
			"<leader>bf",
			":Neotree buffers reveal float<CR>",
			{ desc = "Open Neo-tree buffer explorer in float" }
		)

		-- Additional keymaps for quick access
		vim.keymap.set("n", "<leader>e", ":Neotree toggle right<CR>", { desc = "Toggle Neo-tree" })
		vim.keymap.set("n", "<leader>gs", ":Neotree git_status<CR>", { desc = "Open Neo-tree git status" })
	end,
}
