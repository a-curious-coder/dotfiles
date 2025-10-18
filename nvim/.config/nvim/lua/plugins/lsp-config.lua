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
			local cmp_capabilities = require('cmp_nvim_lsp').default_capabilities()

			-- Set up LSP attachments and keymaps for each buffer
			local function setup_buffer_lsp(client, bufnr)
				utils.notify_lsp_status(client, bufnr)
				keymaps.setup(bufnr)
			end

			-- Configure each LSP server with modern vim.lsp.config API
			for server_name, server_config in pairs(servers.server_configs) do
				-- Merge server-specific settings with common capabilities
				local config = vim.tbl_deep_extend("force", {
					capabilities = cmp_capabilities,
					on_attach = setup_buffer_lsp,
				}, server_config)
				
				-- Use new vim.lsp.config API (Neovim 0.11+)
				vim.lsp.config(server_name, config)
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
