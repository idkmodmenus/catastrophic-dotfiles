hl.config({
    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
        disable_splash_rendering = true,
        initial_workspace_tracking = 1,
        on_focus_under_fullscreen = 1,
        allow_session_lock_restore = true,

        -- Wake a sleeping screen (dpms off) on any key press or mouse movement, even if
        -- hypridle is not running; hypridle's own resume still handles the normal case.
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
    },

    -- Hyprland's update news and donation reminders pop up on the desktop
    ecosystem = {
        no_update_news   = true,
        no_donation_nag  = true,
    },
})
