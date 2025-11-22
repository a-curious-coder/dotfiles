local banners = {}

local neovim = [[
                                   __
      ___     ___    ___   __  __ /\_\    ___ ___
     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\
    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \
    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\
     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]]

local neovim_block = [[
     ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
     ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
     ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
     ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
     ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
     ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

local minimal = [[

        ╭────────────────────────────────────╮
        │                                    │
        │             n e o v i m            │
        │                                    │
        ╰────────────────────────────────────╯]]

local clean = [[

             ┌─┐┌─┐┌─┐┬  ┬┬┌┬┐
             │ ││├┤ │ │└┐┌┘││││
             └─┘└─┘└─┘ └┘ ┴┴ ┴]]

local dots = [[

                    ● ● ●

              . : n e o v i m : .

                    ● ● ●]]

---@type table
local data = {
    logo = {
        neovim = neovim,
        neovim_block = neovim_block,
        minimal = minimal,
        clean = clean,
        dots = dots,
    },
}

-- Get all banners from a category
---@param category "logo"
---@return table
function banners.get_all(category)
    return data[category]
end

-- Get a random banner from a category
---@param category "logo"
---@return string
function banners.get_random(category)
    local items = data[category]
    local keys = {}
    for k, _ in pairs(items) do
        table.insert(keys, k)
    end
    math.randomseed(os.time())
    local random_key = keys[math.random(#keys)]
    return items[random_key]
end

---Get a specific banner
---@param category "logo"
---@return table
function banners.get(category)
    return data[category]
end

return banners
