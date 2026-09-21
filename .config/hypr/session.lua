
-- Environment
local home = os.getenv("HOME")
local path = os.getenv("PATH")

hl.env("PATH", home .. "/.local/bin:" .. path)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Startup
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
end)
