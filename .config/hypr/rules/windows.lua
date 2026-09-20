--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Prevent applications from forcing themselves into maximized state.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Prevent certain XWayland drag helper windows from stealing focus.
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland's run launcher.
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
