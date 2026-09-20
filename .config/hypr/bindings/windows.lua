------------------
---- WINDOWS ----
------------------

-- Close / float / pseudo
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo())

-- Transparency Toggle
hl.bind("SUPER + Backspace", hl.dsp.exec_cmd("hyprland-window-transparency-toggle"))

-- Split
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

-- Focus
hl.bind("SUPER + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + Down",  hl.dsp.focus({ direction = "down" }))

-- Swap
hl.bind("SUPER + SHIFT + Left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + SHIFT + Up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + SHIFT + Down",  hl.dsp.window.swap({ direction = "d" }))

-- Resize
hl.bind("SUPER + code:20", hl.dsp.window.resize({
    x = -100, y = 0, relative = true
}))

hl.bind("SUPER + code:21", hl.dsp.window.resize({
    x = 100, y = 0, relative = true
}))

hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({
    x = 0, y = -100, relative = true
}))

hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({
    x = 0, y = 100, relative = true
}))

-- Mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {
    mouse = true
})

hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {
    mouse = true
})

-- Cycle
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
