-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)
