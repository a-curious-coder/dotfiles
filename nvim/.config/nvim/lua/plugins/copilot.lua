local uv = vim.uv or vim.loop

local function has_copilot_auth()
  local paths = {
    vim.fn.expand("~/.config/github-copilot/hosts.json"),
    vim.fn.expand("~/Library/Application Support/github-copilot/hosts.json"),
  }

  for _, path in ipairs(paths) do
    if uv.fs_stat(path) then
      return true
    end
  end

  return false
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = has_copilot_auth() and "InsertEnter" or nil,
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<C-l>",
          },
        },
        panel = { enabled = false },
      })
    end,
  },
}
