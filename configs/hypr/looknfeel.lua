-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- No gaps between windows or borders.
    gaps_in = 5,
    gaps_out = 5,
    -- border_size = 0,

    -- Change to niri-like side-scrolling layout.
    -- layout = "scrolling",
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
  decoration = {
    -- Use round window corners.
    rounding = 0,

    -- Disable blur.
    blur = {
      enabled = false,
    },

    -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
    dim_inactive = true,
    dim_strength = 0.15,
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
  animations = {
    -- Disable all animations.
    -- enabled = false,
  },

  -- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
  scrolling = {
    -- See only one column per screen instead of two.
    column_width = 0.5,

    -- Alternate column widths.
    explicit_column_widths = "0.5, 1.0",
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
  layout = {
    -- Avoid overly wide single-window layouts on wide screens.
    -- single_window_aspect_ratio = { 1, 1 },
  },
})

-- https://wiki.hypr.land/Configuring/Animations/

-- Workspace animation curve.
hl.curve("snappy", {
  type = "bezier",
  points = {
    { 0.3, 1.0 },
    { 0.4, 1.0 },
  },
})

-- Workspace switching animation.
hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 1.7,
  bezier = "snappy",
  style = "slide",
})

-- https://wiki.hypr.land/Configuring/Window-Rules/

-- Keep tagged windows fully opaque.
hl.window_rule({
  match = { tag = "chromium-based-browser" },
  opacity = 1,
})

hl.window_rule({
  match = { tag = "firefox-based-browser" },
  opacity = 1,
})

hl.window_rule({
  match = { tag = "terminal" },
  opacity = 1,
})

hl.window_rule({
  match = { tag = "default-opacity" },
  opacity = 1,
})
