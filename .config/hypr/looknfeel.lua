-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 6,

        border_size = 0,

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",	
    },

    decoration = {
        rounding = 0,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,
     
	dim_inactive = true,
        dim_strength = 0.15,
 

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled = false,
        },
    },
})

hl.config({
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
})

hl.config({
    scrolling = {
	 column_width = 0.5,

-- Alternate column widths.

    explicit_column_widths = "0.5, 1.0",

    },
})


