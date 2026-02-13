local function centered_width()
	local total_columns = vim.o.columns
	local width_by_ratio = math.floor(total_columns * 0.6)
	local max_content_columns = 100 -- ~800px equivalent in a typical terminal font
	local min_content_columns = 60
	local target_width = math.min(width_by_ratio, max_content_columns)
	local max_allowed_width = math.max(1, total_columns - 4)

	return math.max(1, math.min(max_allowed_width, math.max(min_content_columns, target_width)))
end

local function toggle_centered_layout()
	require("zen-mode").toggle({
		window = {
			width = centered_width(),
		},
	})
end

return {
	"folke/zen-mode.nvim",
	cmd = {
		"ZenMode",
	},
	keys = {
		{
			"<leader>uc",
			toggle_centered_layout,
			desc = "Toggle centered layout",
		},
		{
			"<D-S-c>",
			toggle_centered_layout,
			desc = "Toggle centered layout",
		},
	},
	opts = {
		window = {
			backdrop = 1,
			options = {
				number = false,
				relativenumber = false,
			},
		},
		plugins = {
			options = {
				enabled = true,
				laststatus = 0,
			},
		},
	},
}
