-- -----------------------------------------------------
-- Layouts & System Settings
-- -----------------------------------------------------

hl.config({
    dwindle = {
        preserve_split = true,
        -- New windows always open to the right of / below the focused one,
        -- wherever the mouse is
        force_split = 2,
    },

    -- Master layout (Super+L): one main window, the others stacked beside it
    -- at equal sizes that adjust on their own
    master = {
        new_status = "slave",
        mfact = 0.55,
        orientation = "left",
    },

    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },
})