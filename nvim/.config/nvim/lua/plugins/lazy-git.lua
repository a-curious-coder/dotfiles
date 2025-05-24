-- LazyGit Neovim Plugin Configuration
-- Plugin: lazygit.nvim
-- Description: Integration of LazyGit with Neovim
return {
	"kdheepak/lazygit.nvim",

	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	-- Lazy load the plugin when these commands are used
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},

	-- Define keymaps
	keys = {
		{
			"<leader>gg",
			"<cmd>LazyGit<cr>",
			desc = "Open LazyGit interface"
		},
	},

	-- Plugin configuration
	config = function()
		-- Window configuration
		vim.g.lazygit_floating_window_scaling_factor = 0.9    -- Window size (90% of screen)
		vim.g.lazygit_floating_window_border_chars = {         -- Custom border chars
			'╭', '─', '╮', '│', '╯', '─', '╰', '│'
		}
		
		-- Behavior configuration
		vim.g.lazygit_floating_window_winblend = 0            -- Window transparency (0-100)
		vim.g.lazygit_use_neovim_remote = 1                   -- Use neovim-remote for better terminal handling
		
		-- Location configuration
		vim.g.lazygit_floating_window_corner_chars = {'╭', '╮', '╯', '╰'} -- Corner characters
		vim.g.lazygit_floating_window_use_plenary = 0         -- Use plenary.nvim for window management
	end,
}
