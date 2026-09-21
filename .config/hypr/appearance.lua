---- Appearance ----
hl.config({
    general = {
        gaps_in = 3, gaps_out = 6,
        border_size = 0,
        resize_on_border = false, allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        active_opacity = 1.0, inactive_opacity = 1.0,
        dim_inactive = true, dim_strength = 0.15,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur = { enabled = false },
    },

---- Layouts ----
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

    scrolling = {
        column_width = 0.5,
        explicit_column_widths = "0.5, 1.0",
    },

---- Miscellaneous ----
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_scale_notification = true,
        focus_on_activate = true,
    },
})

---- Animation curves ----
local animations = true

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

---- Animations ----
hl.animation({ leaf = "global", enabled = animations, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = animations, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = animations, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = animations, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = animations, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = animations, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = animations, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = animations, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = animations, speed = 3.0, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = animations, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = animations, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = animations, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = animations, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = animations, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = animations, speed = 1, bezier = "easeOutQuint" })
