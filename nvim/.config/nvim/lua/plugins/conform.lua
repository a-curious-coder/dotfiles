return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true }) end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    formatters = {
      -- Only run prettier when the project has a local prettier config.
      -- Prevents global default rules from overriding project conventions.
      prettier = {
        condition = function(_, ctx)
          return vim.fs.find(
            {
              ".prettierrc", ".prettierrc.json", ".prettierrc.js",
              ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.yaml",
              ".prettierrc.yml", "prettier.config.js", "prettier.config.cjs",
              "prettier.config.mjs",
            },
            { path = ctx.dirname, upward = true }
          )[1] ~= nil
        end,
      },
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
