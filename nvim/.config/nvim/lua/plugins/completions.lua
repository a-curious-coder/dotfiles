return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { vim.fn.stdpath("config") .. "/snippets" },
          })
          require("luasnip").filetype_extend("vue", { "typescript", "javascript" })
        end,
      },
    },
    opts = {
      snippets = { preset = "luasnip" },
      keymap = {
        preset = "default",
        ["<CR>"]  = { "accept", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      cmdline = {
        keymap = { preset = "cmdline" },
        completion = { menu = { auto_show = true } },
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
          window = { border = "rounded" },
        },
        menu = { border = "rounded" },
      },
    },
  },
}
