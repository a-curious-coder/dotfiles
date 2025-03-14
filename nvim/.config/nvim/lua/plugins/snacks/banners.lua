local bannars = {}
local the_lab = [[
████████╗██╗  ██╗███████╗    ██╗      █████╗ ██████╗ 
╚══██╔══╝██║  ██║██╔════╝    ██║     ██╔══██╗██╔══██╗
   ██║   ███████║█████╗      ██║     ███████║██████╔╝
   ██║   ██╔══██║██╔══╝      ██║     ██╔══██║██╔══██╗
   ██║   ██║  ██║███████╗    ███████╗██║  ██║██████╔╝
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ]]
local the_lab2 = [[ 
 ________ __                     __                __       
|        \  \                   |  \              |  \      
 \▓▓▓▓▓▓▓▓ ▓▓____   ______      | ▓▓       ______ | ▓▓____  
   | ▓▓  | ▓▓    \ /      \     | ▓▓      |      \| ▓▓    \ 
   | ▓▓  | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\    | ▓▓       \▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\
   | ▓▓  | ▓▓  | ▓▓ ▓▓    ▓▓    | ▓▓      /      ▓▓ ▓▓  | ▓▓
   | ▓▓  | ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓    | ▓▓_____|  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
   | ▓▓  | ▓▓  | ▓▓\▓▓     \    | ▓▓     \\▓▓    ▓▓ ▓▓    ▓▓
    \▓▓   \▓▓   \▓▓ \▓▓▓▓▓▓▓     \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓\▓▓▓▓▓▓▓ ]]

local neovim_header = [[
                                   __
      ___     ___    ___   __  __ /\_\    ___ ___
     / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\
    /\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \
    \ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\
     \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]]

local neovim_rich = [[
     ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
     ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
     ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
     ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
     ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
     ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

---@type table
local data = {
    logo = {
        TheLab = the_lab,
        TheLab2 = the_lab2,
        Neovim = neovim_header,
        Neovim_rich = neovim_rich,
    },
}

---Get a specific bannar set.
---@param category "logo"
---@return table
function bannars.get(category)
    return data[category]
end

return bannars
