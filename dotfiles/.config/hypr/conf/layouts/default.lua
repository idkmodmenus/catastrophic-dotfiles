hl.config({
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

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