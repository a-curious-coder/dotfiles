local active = require("theme").get():sub(1, 10) == "catppuccin"
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = not active,
  event = not active and "VeryLazy" or nil,
  priority = active and 998 or nil,
}
