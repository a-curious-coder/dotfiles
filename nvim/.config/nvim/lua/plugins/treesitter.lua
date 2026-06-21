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
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = false },
			})
		end
	}
}
