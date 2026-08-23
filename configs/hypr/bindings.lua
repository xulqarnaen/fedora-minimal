-- ============================================================================
-- Custom keybinds
-- Keep Omarchy's default behavior, only restore preferred keybindings.
-- ============================================================================

-- ============================================================================
-- Applications
-- ============================================================================

-- Move File Manager from Super+Shift+F -> Super+E
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })

-- Move File Manager (cwd) from Super+Alt+Shift+F -> Super+Alt+E
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + E", "File manager (cwd)", { omarchy = "nautilus-cwd" })

-- Move Browser from Super+Shift+B -> Super+B
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + B", "Browser", { omarchy = "browser" })

-- Replace Browser with Private Browser on Super+Shift+B
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })

-- Keep Youtui on Super+M.
o.bind("SUPER + M", "Music", { tui = "youtui", focus = true })

-- Keep CLIAMP on Super+Alt+M.
o.bind("SUPER + ALT + M", "Local music", {
  tui = "cliamp /home/ibr/Music/Albums/Piñata",
  focus = true,
})

-- Remove Omarchy's extra music shortcut.
hl.unbind("SUPER + SHIFT + ALT + M")

-- Move Editor from Super+Shift+N -> Super+N
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + N", "Editor", { omarchy = "editor" })


-- ============================================================================
-- Web apps
-- ============================================================================

-- Replace Grok with Claude
o.bind("SUPER + ALT + A", "Claude", {
  webapp = "https://claude.ai"
})

-- Replace ChatGPT with Gemini
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Gemini", {
  webapp = "https://gemini.google.com"
})

-- Move ChatGPT to Super+A
o.bind("SUPER + A", "ChatGPT", {
  webapp = "https://chatgpt.com"
})

-- Replace HEY Calendar with Google Calendar
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", {
  webapp = "https://calendar.google.com"
})

-- Replace HEY Mail with Gmail
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Gmail", {
  webapp = "https://mail.google.com"
})

-- Move YouTube from Super+Shift+Y -> Super+Y
hl.unbind("SUPER + SHIFT + Y")
o.bind("SUPER + Y", "YouTube", {
  webapp = "https://youtube.com"
})

-- Disable the online YouTube Music shortcut.
hl.unbind("SUPER + SHIFT + M")

-- Replace Signal with GitHub
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "GitHub", {
  webapp = "https://github.com"
})

-- Replace Editor with Google Keep
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Keep", {
  webapp = "https://keep.google.com"
})

-- Add Discord
o.bind("SUPER + D", "Discord", {
  webapp = "https://discord.com/channels/@me"
})


-- ============================================================================
-- Window management
-- ============================================================================

-- Replace Fullscreen with Maximized
hl.unbind("SUPER + F")
o.bind("SUPER + F", "Full width",
  hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Move Fullscreen from Super+Alt+F -> Super+Shift+F
hl.unbind("SUPER + ALT + F")
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Full screen",
  hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Move Scratchpad from Super+Alt+S -> Super+Shift+S
hl.unbind("SUPER + ALT + S")
o.bind("SUPER + SHIFT + S", "Move window to scratchpad",
  hl.dsp.window.move({
    workspace = "special:scratchpad",
    follow = false,
  }))

-- Disable the default Close Window shortcut (Super+W)
hl.unbind("SUPER + W")

-- Use Super+Q to close windows
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())


-- ============================================================================
-- Screenshots
-- ============================================================================

-- Screenshot selection directly to clipboard
o.bind("SHIFT + PRINT", "Screenshot to clipboard",
  'grim -g "$(slurp)" - | wl-copy')


-- ============================================================================
-- Media
-- ============================================================================

o.bind("ALT + M", "Play/Pause", "omarchy-shell media playPause")
o.bind("ALT + N", "Next track", "omarchy-shell media next")
o.bind("ALT + B", "Previous track", "omarchy-shell media previous")


-- ============================================================================
-- Layout
-- ============================================================================

-- Restore old column resize shortcut
o.bind("ALT + F", "Toggle column width",
  hl.dsp.layout("colresize +conf"))
