------------------
---- WEB APPS ----
------------------

local webapp = require("programs").webapp

hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(
    webapp .. " https://gemini.google.com"
))

hl.bind("SUPER + A", hl.dsp.exec_cmd(
    webapp .. " https://chatgpt.com"
))

hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd(
    webapp .. " https://calendar.google.com"
))

hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(
    webapp .. " https://mail.google.com"
))

hl.bind("SUPER + Y", hl.dsp.exec_cmd(
    webapp .. " https://youtube.com"
))

hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd(
    webapp .. " https://music.youtube.com"
))

hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(
    webapp .. " https://github.com"
))

hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(
    webapp .. " https://keep.google.com"
))

hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(
    webapp .. " https://discord.com/channels/@me"
))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd(
    webapp .. " https://photos.google.com"
))
