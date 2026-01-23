return {
	{
		-- TreeSitter plugin for advanced syntax highlighting and code parsing
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			-- Import TreeSitter configuration module
			local treesitter = require("nvim-treesitter.configs")

			-- Setup TreeSitter with common configuration options
			treesitter.setup({
				-- Automatically install missing parsers
				auto_install = true,

				-- Enable syntax highlighting
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = true,
				},

				-- Disable automatic indentation
				indent = { 
					enable = false 
				},
			})
		end
	}
}
