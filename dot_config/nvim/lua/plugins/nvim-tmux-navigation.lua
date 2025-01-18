-- Only load tmux navigation on non-Windows systems
if vim.fn.has("win32") == 0 then
	return {
		"alexghergh/nvim-tmux-navigation",
		config = function()
			require("nvim-tmux-navigation").setup({
				disable_when_zoomed = true,
				keybindings = {
					left = "<C-h>",
					down = "<C-j>",
					up = "<C-k>",
					right = "<C-l>",
				},
			})
		end,
	}
else
	-- On Windows, return a dummy plugin with just the window navigation
	return {
		"nvim-lua/plenary.nvim", -- Using plenary as a dummy plugin
		config = function()
			vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
			vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
			vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
			vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
		end,
	}
end
