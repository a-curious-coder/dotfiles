return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"mfussenegger/nvim-dap-python",
		"theHamsta/nvim-dap-virtual-text", -- Add virtual text support
		"nvim-telescope/telescope-dap.nvim", -- Add Telescope integration
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		-- Setup Python debugging
		require("dap-python").setup("python")

		-- Setup DAP UI
		dapui.setup({
			-- Customize UI layout and components here
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.25 },
						{ id = "breakpoints", size = 0.25 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.25 },
					},
					size = 40,
					position = "left",
				},
				{
					elements = {
						{ id = "repl", size = 0.5 },
						{ id = "console", size = 0.5 },
					},
					size = 10,
					position = "bottom",
				},
			},
		})

		-- Configure DAP signs
		vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
		vim.fn.sign_define(
			"DapStopped",
			{ text = "▶️", texthl = "DiagnosticSignWarn", linehl = "Visual", numhl = "" }
		)

		-- Automatically open and close DAP UI
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Setup virtual text
		require("nvim-dap-virtual-text").setup()

		-- Setup Telescope DAP integration
		require("telescope").load_extension("dap")

		-- Keymaps
		local opts = { noremap = true, silent = true }
		vim.keymap.set("n", "<Leader>dt", dap.toggle_breakpoint, opts)
		vim.keymap.set("n", "<Leader>dc", dap.continue, opts)
		vim.keymap.set("n", "<Leader>dj", dap.step_over, opts)
		vim.keymap.set("n", "<Leader>di", dap.step_into, opts)
		vim.keymap.set("n", "<Leader>do", dap.step_out, opts)
		vim.keymap.set("n", "<Leader>dr", dap.repl.open, opts)
		vim.keymap.set("n", "<Leader>dl", dap.run_last, opts)
		vim.keymap.set("n", "<Leader>du", dapui.toggle, opts)
		vim.keymap.set("n", "<Leader>db", function()
			require("telescope").extensions.dap.list_breakpoints({})
		end, opts)
		vim.keymap.set("n", "<Leader>dv", function()
			require("telescope").extensions.dap.variables({})
		end, opts)
		vim.keymap.set("n", "<Leader>df", function()
			require("telescope").extensions.dap.frames({})
		end, opts)
	end,
}
