-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt6ct


-- Cursor size
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Make user-installed executables available to Hyprland/apps
local home = os.getenv("HOME")

hl.env(
    "PATH",
    home .. "/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
)
