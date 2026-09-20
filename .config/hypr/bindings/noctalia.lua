
------------------
---- NOCTALIA ----
------------------

local ipc = "noctalia msg "


------------------
---- PANELS ------
------------------

hl.bind("SUPER + Space",       hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind("SUPER + ALT + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind("SUPER + SHIFT + Space", hl.dsp.exec_cmd(ipc .. "bar-toggle"))

hl.bind("SUPER + CTRL + V",    hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))
hl.bind("SUPER + CTRL + Space", hl.dsp.exec_cmd(ipc .. "panel-toggle wallpaper"))
hl.bind("SUPER + CTRL + ALT + Space", hl.dsp.exec_cmd(ipc .. "wallpaper-random"))
hl.bind("SUPER + CTRL + S",    hl.dsp.exec_cmd(ipc .. "settings-toggle"))


------------------
---- SCREENSHOTS -
------------------

hl.bind("Print",        hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen pick"))
hl.bind("CTRL + Print",  hl.dsp.exec_cmd(ipc .. "screenshot-region"))


------------------
---- TOGGLES -----
------------------

hl.bind("SUPER + CTRL + I", hl.dsp.exec_cmd(ipc .. "caffeine-toggle"))
hl.bind("SUPER + CTRL + N", hl.dsp.exec_cmd(ipc .. "nightlight-force-toggle"))


------------------
---- CONTROL CENTER
------------------

-- Notifications
hl.bind("SUPER + N", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center notifications"
))

-- Media
hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center media"
))

-- Network
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center network"
))

-- Bluetooth
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center bluetooth"
))

-- Audio
hl.bind("SUPER + CTRL + A", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center audio"
))

-- Monitor
hl.bind("SUPER + CTRL + D", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center monitor"
))

-- Power
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center power"
))

-- Calendar
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd(
    ipc .. "panel-toggle control-center calendar"
))

------------------
---- SESSION -----
------------------

hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind("SUPER + Escape",   hl.dsp.exec_cmd(ipc .. "panel-toggle session"))
