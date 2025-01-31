return {
	"vim-test/vim-test",
	dependencies = vim.fn.has("win32") == 0 and { "preservim/vimux" } or {},
	config = function()
		vim.keymap.set("n", "<leader>t", ":TestNearest<CR>", {})
		vim.keymap.set("n", "<leader>T", ":TestFile<CR>", {})
		vim.keymap.set("n", "<leader>a", ":TestSuite<CR>", {})
		vim.keymap.set("n", "<leader>l", ":TestLast<CR>", {})
		vim.keymap.set("n", "<leader>g", ":TestVisit<CR>", {})

		-- Use different test strategies based on OS
		if vim.fn.has("win32") == 1 then
			vim.cmd("let test#strategy = 'neovim'") -- Use neovim strategy on Windows
		else
			vim.cmd("let test#strategy = 'vimux'") -- Use vimux strategy on Unix-like systems
		end
	end,
}
