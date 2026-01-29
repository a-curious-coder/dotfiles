local last_nonterminal_tab = nil

local function toggle_terminal_tab()
	if vim.fn.tabpagenr() == 0 then
		return
	end

	if vim.bo.buftype == "terminal" then
		if last_nonterminal_tab and last_nonterminal_tab ~= vim.fn.tabpagenr() then
			vim.cmd("tabnext " .. last_nonterminal_tab)
			return
		end

		vim.cmd("tabprevious")
		return
	end

	require("toggleterm").toggle({ direction = "tab" })
end

local function remember_last_file_tab()
	if vim.bo.buftype ~= "terminal" then
		last_nonterminal_tab = vim.fn.tabpagenr()
	end
end

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
			function()
				toggle_terminal_tab()
			end,
			desc = "Toggle terminal tab",
		},
	},
	config = function()
		require("toggleterm").setup({
			-- Use a dedicated tab for every terminal so `gt`/`gT` can flip between them
			direction = "tab",
			close_on_exit = true,
			persist_size = true,
			start_in_insert = true,
			open_mapping = "<c-\\>",
			-- Tab terminals already occupy the full screen, so shading/non-shading doesn't matter.
			shade_terminals = false,
		})

		local aug = vim.api.nvim_create_augroup("ToggleTermTabs", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "TabEnter" }, {
			group = aug,
			callback = remember_last_file_tab,
			desc = "Track the last non-terminal tab for toggleterm",
		})

		-- Mirror the toggle key in terminal mode so the mapping works without manually leaving insert
		vim.keymap.set("t", "<leader>tt", toggle_terminal_tab, { desc = "Toggle terminal tab" })
	end,
}
