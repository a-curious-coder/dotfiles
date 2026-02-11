return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	cmd = { "RenderMarkdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		file_types = { "markdown" },
	},
	keys = {
		{
			"<leader>um",
			function()
				if vim.bo.filetype ~= "markdown" then
					vim.notify("Open a markdown buffer to toggle read view", vim.log.levels.INFO)
					return
				end
				require("render-markdown").buf_toggle()
			end,
			desc = "Toggle markdown read view",
		},
		{
			"<leader>uM",
			function()
				if vim.bo.filetype ~= "markdown" then
					vim.notify("Open a markdown buffer to preview", vim.log.levels.INFO)
					return
				end
				vim.cmd("RenderMarkdown preview")
			end,
			desc = "Preview markdown split",
		},
	},
}
