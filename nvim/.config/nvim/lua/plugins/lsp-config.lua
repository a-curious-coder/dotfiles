return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      local servers = require("lsp.servers")
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers.server_configs),
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      local keymaps = require("lsp.keymaps")
      local servers = require("lsp.servers")
      local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

      for server_name, server_config in pairs(servers.server_configs) do
        vim.lsp.config(server_name, vim.tbl_deep_extend("force", {
          capabilities = cmp_capabilities,
        }, server_config))
        vim.lsp.enable(server_name)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev) keymaps.setup(ev.buf) end,
      })
    end,
  },
}
