return {
	{
		-- TreeSitter plugin (main branch: parser manager only, no `configs` module)
		"nvim-treesitter/nvim-treesitter",
		branch = "main", -- old clones still track master, which this config breaks on
		lazy = false,
		build = ":TSUpdate",
		config = function()
			-- Highlighting is now Neovim's built-in; start it per buffer when a parser exists
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})

			-- Installing parsers needs the tree-sitter CLI and a C compiler
			-- shortcut: no parser auto-install, add languages to this list once both tools exist
			if vim.fn.executable("tree-sitter") == 1 then
				require("nvim-treesitter").install({ "lua", "vim", "vimdoc", "markdown", "javascript", "python" })
			end
		end,
	},
}
