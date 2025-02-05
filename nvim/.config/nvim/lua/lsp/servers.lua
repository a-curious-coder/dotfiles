local M = {}

M.server_configs = {
  html = {},
  jsonls = {},
  lua_ls = {},
  pyright = {},
  pylsp = {},
  ruby_lsp = {
    cmd = { "ruby-lsp" },
    settings = {
      rubocop = {
        enable = true,
        lint = true,
        format = true
      }
    }
  },
  tailwindcss = {
    root_dir = function(fname)
      return require("lspconfig").util.root_pattern("tailwind.config.js", "tailwind.config.cjs")(fname)
    end
  },
  volar = {
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json' },
    cmd = { 'vue-language-server', '--stdio' }
  }
}

return M
