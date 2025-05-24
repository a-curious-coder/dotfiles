return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			background = {
				dark = "mocha",
			},
			color_overrides = {
				mocha = {
					-- Simplified color palette
					text = "#f1e4c2",
					subtext1 = "#d5c4a1",
					subtext0 = "#bdae93",
					overlay2 = "#a89984",
					overlay1 = "#928374",
					overlay0 = "#595959",
					surface2 = "#4d4d4d",
					surface1 = "#404040",
					surface0 = "#292929",
					base = "#1d2224",
					mantle = "#1d2224",
					crust = "#1f2223",
					
					-- Core syntax colors
					red = "#FB4834",
					green = "#8dc07c",
					blue = "#8dbba3",
					yellow = "#FBBD2E",
					peach = "#e78a4e",
					mauve = "#d3859b",
					teal = "#99c792",
				},
			},
			transparent_background = true,
			show_end_of_buffer = false,
			integrations = {
				cmp = true,
				gitsigns = true,
				native_lsp = { enabled = true },
				treesitter = true,
			},
			highlight_overrides = {
				all = function(colors)
					return {
						-- Basic UI elements
						Normal = { fg = colors.text },
						CursorLine = { bg = colors.surface0 },
						LineNr = { fg = colors.overlay0 },
						SignColumn = { bg = "NONE" },
						
						-- Syntax highlighting
						Keyword = { fg = colors.red },
						Function = { fg = colors.green },
						String = { fg = colors.teal },
						Number = { fg = colors.mauve },
						Comment = { fg = colors.overlay1 },
						Type = { fg = colors.yellow },
						
						-- Remove most bold styles
						["@function"] = { fg = colors.green },
						["@type"] = { fg = colors.yellow },
						["@keyword"] = { fg = colors.red },
					}
				end,
			},
		})

		vim.api.nvim_command("colorscheme catppuccin-mocha")
	end,
}
