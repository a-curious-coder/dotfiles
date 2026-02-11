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
				visible = false, -- Hide filtered items by default
				show_hidden_count = false,
				hide_dotfiles = true,
				hide_gitignored = true,
				hide_ignored = true,
			},
			follow_current_file = {
				enabled = true,
				leave_dirs_open = true,
			},
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
				["H"] = "toggle_hidden",
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
		vim.keymap.set("n", "<leader>ue", function()
			require("neo-tree.command").execute({
				toggle = true,
				reveal = true,
				position = "right",
			})
		end, { desc = "Toggle Neo-tree" })
	end,
}
