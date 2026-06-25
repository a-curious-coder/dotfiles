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
      -- ruby_lsp is driven by the rbenv shim, not Mason (per-project Ruby version)
      local ensure = vim.tbl_filter(function(n) return n ~= "ruby_lsp" end, vim.tbl_keys(servers.server_configs))
      require("mason-lspconfig").setup({ ensure_installed = ensure })
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
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      for server_name, server_config in pairs(servers.server_configs) do
        vim.lsp.config(server_name, vim.tbl_deep_extend("force", {
          capabilities = capabilities,
        }, server_config))
        vim.lsp.enable(server_name)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev) keymaps.setup(ev.buf) end,
      })
    end,
  },
}
