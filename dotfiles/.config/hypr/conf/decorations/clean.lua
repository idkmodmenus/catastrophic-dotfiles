-- -----------------------------------------------------
-- General window decoration
-- name: "Clean"
-- Opaque windows and a light, cached blur (xray) for transparent apps only
-- -----------------------------------------------------

hl.config({
    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = "rgba(00000055)",
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            xray = true,
        },
    },
})
