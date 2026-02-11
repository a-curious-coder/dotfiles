return {
	"akinsho/toggleterm.nvim",
	version = "*",
	cmd = {
		"ToggleTerm",
		"TermSelect",
	},
	keys = {
		{
			"<leader>tt",
			"<cmd>ToggleTerm direction=float<CR>",
			mode = { "n", "t" },
			desc = "Toggle terminal",
		},
	},
	opts = {
		direction = "float",
		float_opts = {
			border = "rounded",
		},
		close_on_exit = true,
		persist_size = true,
		start_in_insert = true,
		shade_terminals = false,
	},
}
