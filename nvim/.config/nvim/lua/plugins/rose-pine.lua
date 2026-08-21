local active = require("theme").get():sub(1, 9) == "rose-pine"
return {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = not active,
  event = not active and "VeryLazy" or nil,
  priority = active and 999 or nil,
}
