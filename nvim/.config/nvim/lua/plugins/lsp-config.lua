local utils = require("lsp.utils")
local keymaps = require("lsp.keymaps")
local servers = require("lsp.servers")

return {
	{
		"williamboman/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			auto_install = true,
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lspconfig = require("lspconfig")

			-- Enhanced on_attach function
			local on_attach = function(client, bufnr)
				utils.notify_lsp_status(client, bufnr)
				keymaps.setup(bufnr)
			end

			-- Setup LSP servers
			for server_name, config in pairs(servers.server_configs) do
				config.capabilities = capabilities
				config.on_attach = on_attach
				lspconfig[server_name].setup(config)
			end

			-- Add status line component
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					vim.b[bufnr].lsp_status = string.format("LSP: %s", client.name)
				end,
			})
		end,
	},
}
