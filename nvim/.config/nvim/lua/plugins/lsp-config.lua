local keymaps = require("lsp.keymaps")
local servers = require("lsp.servers")

return {
  -- Mason: Package manager for LSP servers
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- Mason-LSPConfig: Auto-install servers
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = true,
      })
    end,
  },

  -- nvim-lspconfig: Server configurations (use vim.lsp.config on Nvim 0.11+)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configure each server with vim.lsp.config
      for server_name, server_config in pairs(servers.server_configs) do
        local config = vim.tbl_deep_extend("force", {
          capabilities = cmp_capabilities,
        }, server_config)

        vim.lsp.config(server_name, config)
        vim.lsp.enable(server_name)
      end

      -- Set up keymaps when LSP attaches to buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          keymaps.setup(ev.buf)
        end,
      })
    end,
  },
}
