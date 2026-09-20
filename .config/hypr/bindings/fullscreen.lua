---------------------
---- FULLSCREEN ----
---------------------

-- Normal fullscreen
hl.bind("SUPER + F", hl.dsp.window.fullscreen({
    mode = 1
}))

hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({
    mode = 0
}))

-- Tiled fullscreen
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen_state({
    internal = 0,
    client = 2,
    action = "toggle"
}))
