return {
	"romgrk/barbar.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"lewis6991/gitsigns.nvim",
	}, -- Optional: For file icons
	config = function()
		require("barbar").setup({
			animation = true, -- Enable animations
			auto_hide = false, -- Automatically hide the tab bar when there's only one buffer
			tabpages = true,
			clickable = true, -- Allow clicking on buffers to switch
			icons = {
				buffer_index = true,
				buffer_number = false,
				button = "",
				filetype = {
					enabled = true, -- Enable filetype icons
					custom_colors = false, -- Use custom colors for filetype icons
				},
				separator = { left = "▎", right = "▎" }, -- Custom separators
			},
			semantic_letters = true,
			letters = "asdfghjkl;qwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM",
			no_name_title = "New Tab",
		})

		local opts = { noremap = true, silent = true }
		-- Buffer navigation
		vim.keymap.set("n", "<leader>bp", "<Cmd>BufferPrevious<CR>", opts) -- Previous buffer
		vim.keymap.set("n", "<leader>bn", "<Cmd>BufferNext<CR>", opts) -- Next buffer

		-- Select individual buffers using leader key + number
		for i = 1, 9 do
			vim.keymap.set("n", "<leader>" .. i, "<Cmd>BufferGoto " .. i .. "<CR>", opts)
		end

		vim.keymap.set("n", "<leader>bc", "<Cmd>BufferDelete<CR>", opts) -- Delete current buffer
		vim.keymap.set("n", "<leader>bl", "<Cmd>BufferLast<CR>", opts) -- Go to last buffer

		-- Move buffers left or right (optional)
		vim.keymap.set("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts) -- Move current buffer left
		vim.keymap.set("n", "<A->>", "<Cmd>BufferMoveNext<CR>", opts) -- Move current buffer right

		-- Pin/unpin buffer (optional)
		vim.keymap.set("n", "<A-p>", "<Cmd>BufferPin<CR>", opts) -- Pin the current buffer

		-- Optional: Map to toggle the buffer bar visibility
		vim.keymap.set("n", "<leader>bT", "<Cmd>BufferToggle<CR>", opts)
	end,
}
