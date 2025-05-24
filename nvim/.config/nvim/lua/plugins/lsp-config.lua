-- Core LSP configuration components
local utils = require("lsp.utils")
local keymaps = require("lsp.keymaps")
local servers = require("lsp.servers")

-- LSP plugin configurations
return {
	-- Mason: Package manager for LSP servers
	{
		"williamboman/mason.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason-LSPConfig: Bridge between Mason and LSPConfig
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			auto_install = true,
		},
	},

	-- LSPConfig: Core LSP client configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

			-- Set up LSP attachments and keymaps for each buffer
			local function setup_buffer_lsp(client, bufnr)
				utils.notify_lsp_status(client, bufnr)
				keymaps.setup(bufnr)
			end

			-- Configure each LSP server with common capabilities
			for server_name, config in pairs(servers.server_configs) do
				lspconfig[server_name].setup({
					capabilities = cmp_capabilities,
					on_attach = setup_buffer_lsp,
					-- Merge server-specific settings
					unpack(config)
				})
			end

			-- Update statusline with active LSP info
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					vim.b[ev.buf].lsp_status = string.format("LSP: %s", client.name)
				end,
			})
		end,
	},
}
