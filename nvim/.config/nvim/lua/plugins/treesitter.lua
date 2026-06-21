return {
	{
		-- TreeSitter plugin for advanced syntax highlighting and code parsing
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			-- Import TreeSitter configuration module
			local treesitter = require("nvim-treesitter.configs")

			-- Setup TreeSitter with common configuration options
			-- ponytail: highlight disabled — nvim-treesitter query predicates crash on
			-- Nvim 0.12.3. Nvim's built-in treesitter highlighter takes over automatically.
			treesitter.setup({
				auto_install = true,
				highlight = { enable = false },
				indent = { enable = false },
			})
		end
	}
}
