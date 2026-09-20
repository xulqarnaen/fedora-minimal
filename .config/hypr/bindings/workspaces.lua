---------------------
---- WORKSPACES ----
---------------------

-- Switch / move
for i = 1, 10 do
    local key = i % 10

    hl.bind("SUPER + " .. key, hl.dsp.focus({
        workspace = i
    }))

    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({
        workspace = i
    }))
end

-- Navigate
hl.bind("SUPER + Tab", hl.dsp.focus({
    workspace = "e+1"
}))

hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({
    workspace = "e-1"
}))

hl.bind("SUPER + CTRL + Tab", hl.dsp.focus({
    workspace = "previous"
}))

-- Special workspace
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))

hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({
    workspace = "special:scratchpad",
    follow = false
}))

-- Workspace layout toggle script
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprland-workspace-layout-toggle"), {
    description = "Toggle workspace layout"
})

hl.bind("SUPER + D", hl.dsp.layout("colresize +conf"))
