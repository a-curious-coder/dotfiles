return {
  "echasnovski/mini.animate",
  version = false,
  event = "VeryLazy",
  config = function()
    require("mini.animate").setup({
      scroll = {
        timing = require("mini.animate").gen_timing.linear({ duration = 80, unit = "total" }),
      },
      cursor = { enable = false },
      resize = { enable = false },
      open = { enable = false },
      close = { enable = false },
    })
  end,
}
