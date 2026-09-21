local programs = require("programs")
local ipc = programs.noctalia
local webapp = programs.webapp

-- Applications
hl.bind("SUPER + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind("SUPER + B", hl.dsp.exec_cmd(programs.browser))
hl.bind("SUPER + E", hl.dsp.exec_cmd(programs.fileManager))

-- Web apps
hl.bind("SUPER + A", hl.dsp.exec_cmd(webapp .. " https://chatgpt.com"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd(webapp .. " https://youtube.com"))
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(webapp .. " https://gemini.google.com"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd(webapp .. " https://calendar.google.com"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(webapp .. " https://mail.google.com"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd(webapp .. " https://music.youtube.com"))
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(webapp .. " https://github.com"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(webapp .. " https://keep.google.com"))
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(webapp .. " https://discord.com/channels/@me"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd(webapp .. " https://photos.google.com"))

-- Windows
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + Backspace", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))
hl.bind("SUPER + J", function()
    local ws = hl.get_active_workspace()
    if ws and ws.tiled_layout == "dwindle" then hl.dispatch(hl.dsp.layout("togglesplit")) end
end)

-- Focus
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())

-- Swap
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.swap({ direction = "d" }))

-- Resize
hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Special workspace
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Workspace layout
hl.bind("SUPER + L", function()
    local ws = hl.get_active_workspace()
    if not ws then return end

    local layout = ws.tiled_layout == "dwindle" and "scrolling" or "dwindle"
    local target = ws.special and tostring(ws.name) or "name:" .. tostring(ws.name)

    hl.workspace_rule({ workspace = target, layout = layout })
    hl.exec_cmd(ipc .. 'notification-show "' .. layout:gsub("^%l", string.upper) .. ' layout"')
end)

hl.bind("SUPER + D", hl.dsp.layout("colresize +conf"))

-- Fullscreen
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" }))

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. "media toggle"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "media toggle"))
hl.bind("ALT + M", hl.dsp.exec_cmd(ipc .. "media toggle"))
hl.bind("ALT + B", hl.dsp.exec_cmd(ipc .. "media previous"))
hl.bind("ALT + N", hl.dsp.exec_cmd(ipc .. "media next"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), { locked = true, repeating = false })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(ipc .. "mic-mute"), { locked = true, repeating = fasle })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), { locked = true, repeating = true })

-- Noctalia panels
hl.bind("SUPER + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind("SUPER + ALT + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind("SUPER + SHIFT + Space", hl.dsp.exec_cmd(ipc .. "bar-toggle"))
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))
hl.bind("SUPER + CTRL + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle wallpaper"))
hl.bind("SUPER + CTRL + ALT + Space", hl.dsp.exec_cmd(ipc .. "wallpaper-random"))
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd(ipc .. "settings-toggle"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd(ipc .. "screenshot-region"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("screenrecord"))

-- Noctalia toggles
hl.bind("SUPER + CTRL + I", hl.dsp.exec_cmd(ipc .. "caffeine-toggle"))
hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd(ipc .. "nightlight-force-toggle"))

-- Noctalia control center
hl.bind("SUPER + N", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center notifications"))
hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center media"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center network"))
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center bluetooth"))
hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center audio"))
hl.bind("SUPER + CTRL + D", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center monitor"))
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center power"))
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center calendar"))

-- Notifications
hl.bind("SUPER + comma", hl.dsp.exec_cmd(ipc .. "notification-clear-active"))

-- Session
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
