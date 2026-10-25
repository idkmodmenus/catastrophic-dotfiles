-- Keep sending frames to these apps while their workspace is hidden (at
-- misc.render_unfocused_fps), so video, screen shares, music and games keep
-- running instead of freezing until you switch back
hl.window_rule({
    name = "render-unfocused",
    match = { class = "^(firefox|discord|vesktop|[Ss]potify|obs|com\\.obsproject\\.Studio|mpv|steam_app_[0-9]+)$" },
    render_unfocused = true,
})
