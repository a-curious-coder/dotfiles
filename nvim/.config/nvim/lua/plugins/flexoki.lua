local active = require("theme").get():sub(1, 7) == "flexoki"
return {
  "kepano/flexoki-neovim",
  name = "flexoki",
  lazy = not active,
  event = not active and "VeryLazy" or nil,
  priority = active and 1000 or nil,
}
