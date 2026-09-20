----------------
---- MEDIA ----
----------------

local noctalia = require("programs").noctalia

-- Playback
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(
    noctalia .. "media toggle"
))

hl.bind("XF86AudioPause", hl.dsp.exec_cmd(
    noctalia .. "media toggle"
))
hl.bind("ALT + M", hl.dsp.exec_cmd(
    noctalia .. "media toggle"
))

hl.bind("ALT + B", hl.dsp.exec_cmd(
    noctalia .. "media previous"
))

hl.bind("ALT + N", hl.dsp.exec_cmd(
    noctalia .. "media next"
))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
    noctalia .. "volume-up"
), {
    locked = true,
    repeating = true
})

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(
    noctalia .. "volume-down"
), {
    locked = true,
    repeating = true
})

hl.bind("XF86AudioMute", hl.dsp.exec_cmd(
    noctalia .. "volume-mute"
), {
    locked = true,
    repeating = true
})

-- Microphone
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(
    noctalia .. "mic-mute"
), {
    locked = true,
    repeating = true
})

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(
    noctalia .. "brightness-up"
), {
    locked = true,
    repeating = true
})

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(
    noctalia .. "brightness-down"
), {
    locked = true,
    repeating = true
})
