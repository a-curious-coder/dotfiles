local aerospaceBin = nil

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function detectAerospace()
  local resolved = trim(hs.execute("/bin/zsh -lc 'command -v aerospace 2>/dev/null'", true) or "")
  if resolved ~= "" then
    return resolved
  end

  local appBin = "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
  if hs.fs.attributes(appBin) then
    return appBin
  end

  return nil
end

aerospaceBin = detectAerospace()

local function aerospace(cmd)
  if not aerospaceBin then
    return
  end
  hs.execute(string.format("%s %s >/dev/null 2>&1", aerospaceBin, cmd), true)
end

local dragState = {
  active = false,
  mode = nil,
  window = nil,
  startMouse = nil,
  startFrame = nil,
}

local function beginDrag(mode)
  local mods = hs.eventtap.checkKeyboardModifiers()
  if not mods.cmd then
    return false
  end

  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() then
    return false
  end

  win:focus()
  aerospace("layout floating")

  dragState.active = true
  dragState.mode = mode
  dragState.window = win
  dragState.startMouse = hs.mouse.absolutePosition()
  dragState.startFrame = win:frame()

  return true
end

local function updateDrag()
  if not dragState.active or not dragState.window then
    return false
  end

  local now = hs.mouse.absolutePosition()
  local dx = now.x - dragState.startMouse.x
  local dy = now.y - dragState.startMouse.y
  local f = dragState.startFrame:copy()

  if dragState.mode == "move" then
    f.x = f.x + dx
    f.y = f.y + dy
  else
    f.w = math.max(320, f.w + dx)
    f.h = math.max(220, f.h + dy)
  end

  dragState.window:setFrame(f, 0)
  return true
end

local function endDrag()
  if not dragState.active then
    return false
  end

  dragState.active = false
  dragState.mode = nil
  dragState.window = nil
  dragState.startMouse = nil
  dragState.startFrame = nil

  return true
end

local dragTap = hs.eventtap.new({
  hs.eventtap.event.types.leftMouseDown,
  hs.eventtap.event.types.leftMouseDragged,
  hs.eventtap.event.types.leftMouseUp,
  hs.eventtap.event.types.rightMouseDown,
  hs.eventtap.event.types.rightMouseDragged,
  hs.eventtap.event.types.rightMouseUp,
}, function(e)
  local et = e:getType()

  if et == hs.eventtap.event.types.leftMouseDown then
    return beginDrag("move")
  end
  if et == hs.eventtap.event.types.rightMouseDown then
    return beginDrag("resize")
  end
  if et == hs.eventtap.event.types.leftMouseDragged or et == hs.eventtap.event.types.rightMouseDragged then
    return updateDrag()
  end
  if et == hs.eventtap.event.types.leftMouseUp or et == hs.eventtap.event.types.rightMouseUp then
    return endDrag()
  end

  return false
end)
dragTap:start()

local appliedRuleByWindow = {}

local function clampToScreen(x, y, w, h, sf)
  local nx = math.max(sf.x, math.min(x, sf.x + sf.w - w))
  local ny = math.max(sf.y, math.min(y, sf.y + sf.h - h))
  return nx, ny
end

local function centerRect(sf, widthPct, heightPct)
  local w = math.floor(sf.w * widthPct)
  local h = math.floor(sf.h * heightPct)
  local x = sf.x + math.floor((sf.w - w) / 2)
  local y = sf.y + math.floor((sf.h - h) / 2)
  return hs.geometry.rect(x, y, w, h)
end

local function pipRect(sf)
  local w = math.floor(sf.w * 0.28)
  local h = math.floor(sf.h * 0.24)
  local x = sf.x + math.floor(sf.w * 0.71)
  local y = sf.y + math.floor(sf.h * 0.07)
  local nx, ny = clampToScreen(x, y, w, h, sf)
  return hs.geometry.rect(nx, ny, w, h)
end

local function applyWindowRules(win)
  if not win or not win:isStandard() then
    return
  end

  local app = win:application()
  if not app then
    return
  end

  local appId = app:bundleID() or ""
  local title = win:title() or ""
  local lower = string.lower(title)
  local signature = appId .. "|" .. lower

  if appliedRuleByWindow[win:id()] == signature then
    return
  end

  local shouldFloat = false
  local frame = nil

  if lower == "picture-in-picture" then
    shouldFloat = true
    frame = pipRect(win:screen():frame())
  elseif lower == "save as" or lower == "add folder to workspace" or string.find(lower, "open files", 1, true) then
    shouldFloat = true
    frame = centerRect(win:screen():frame(), 0.70, 0.60)
  elseif lower == "authentication required" then
    shouldFloat = true
    frame = centerRect(win:screen():frame(), 0.50, 0.34)
  end

  if appId == "com.valvesoftware.steam" and title ~= "Steam" then
    shouldFloat = true
  end
  if appId == "com.heroicgameslauncher.hgl" and title ~= "Heroic Games Launcher" then
    shouldFloat = true
  end

  if appId == "com.apple.systempreferences" or appId == "com.apple.ActivityMonitor" or appId == "com.apple.print.PrintCenter" then
    shouldFloat = true
    frame = centerRect(win:screen():frame(), 0.70, 0.70)
  end
  if appId == "com.apple.Preview" then
    shouldFloat = true
    frame = centerRect(win:screen():frame(), 0.72, 0.72)
  end

  if not shouldFloat then
    return
  end

  appliedRuleByWindow[win:id()] = signature

  win:focus()
  aerospace("layout floating")

  if frame then
    hs.timer.doAfter(0.05, function()
      if win and win:isStandard() then
        win:setFrame(frame, 0)
      end
    end)
  end
end

local windowFilter = hs.window.filter.new()
windowFilter:setDefaultFilter({})
windowFilter:subscribe(hs.window.filter.windowFocused, function(win)
  applyWindowRules(win)
end)
windowFilter:subscribe(hs.window.filter.windowCreated, function(win)
  hs.timer.doAfter(0.05, function()
    applyWindowRules(win)
  end)
end)

local function parseAerospaceBindings()
  local configPath = os.getenv("HOME") .. "/.config/aerospace/aerospace.toml"
  local fh = io.open(configPath, "r")
  if not fh then
    return {}
  end

  local mode = nil
  local out = {}

  for raw in fh:lines() do
    local line = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if line:match("^%[mode%.main%.binding%]") then
      mode = "main"
    elseif line:match("^%[mode%.service%.binding%]") then
      mode = "service"
    elseif line:match("^%[") then
      mode = nil
    elseif mode and line ~= "" and not line:match("^#") then
      local key, cmd = line:match("^([%w%-%._]+)%s*=%s*(.+)$")
      if key and cmd then
        table.insert(out, {
          text = key,
          subText = string.format("%s  |  %s", mode, cmd),
          mode = mode,
          key = key,
          cmd = cmd,
        })
      end
    end
  end

  fh:close()
  return out
end

-- Avoid chooser close restoring focus to another app/workspace.
hs.chooser.globalCallback = function(_, _)
end

local bindingChooser = hs.chooser.new(function(choice)
  if not choice then
    return
  end

  local row = string.format("[%s] %s -> %s", choice.mode, choice.key, choice.cmd)
  hs.pasteboard.setContents(row)
  hs.alert.show("Copied keybinding", 0.8)
end)

bindingChooser:width(40)
bindingChooser:searchSubText(true)

local chooserScreen = nil

local function centerBindingChooser()
  local app = hs.application.find("Hammerspoon")
  if not app then
    return
  end

  local target = nil
  for _, win in ipairs(app:allWindows()) do
    if win:title() == "Chooser" then
      target = win
      break
    end
  end
  if not target then
    return
  end

  local screen = chooserScreen or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  if not screen then
    return
  end

  local sf = screen:frame()
  local wf = target:frame()
  wf.x = sf.x + math.floor((sf.w - wf.w) / 2)
  wf.y = sf.y + math.floor((sf.h - wf.h) / 2)
  target:setFrame(wf, 0)
end

local chooserRecenterTimer = nil

local function queueChooserRecenter(durationSec)
  if chooserRecenterTimer then
    chooserRecenterTimer:stop()
    chooserRecenterTimer = nil
  end

  local interval = 0.05
  local maxTicks = math.max(1, math.floor((durationSec or 0.8) / interval))
  local ticks = 0

  chooserRecenterTimer = hs.timer.doEvery(interval, function()
    if not bindingChooser:isVisible() then
      chooserRecenterTimer:stop()
      chooserRecenterTimer = nil
      return
    end

    centerBindingChooser()
    ticks = ticks + 1
    if ticks >= maxTicks then
      chooserRecenterTimer:stop()
      chooserRecenterTimer = nil
    end
  end)
end

bindingChooser:rows(14)
bindingChooser:showCallback(function()
  queueChooserRecenter(1.2)
end)
bindingChooser:queryChangedCallback(function()
  queueChooserRecenter(0.5)
end)
bindingChooser:hideCallback(function()
  if chooserRecenterTimer then
    chooserRecenterTimer:stop()
    chooserRecenterTimer = nil
  end
end)

hs.urlevent.bind("aerospace-keybindings", function()
  local choices = parseAerospaceBindings()
  if #choices == 0 then
    hs.alert.show("No AeroSpace bindings found", 1.0)
    return
  end

  bindingChooser:choices(choices)
  bindingChooser:placeholderText("Search AeroSpace keybindings")
  local front = hs.window.frontmostWindow()
  chooserScreen = (front and front:screen()) or hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
  bindingChooser:show()
  queueChooserRecenter(1.2)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)

hs.timer.doAfter(1.0, function()
  hs.alert.show("Hammerspoon loaded: cmd+drag enabled", 1.2)
end)
