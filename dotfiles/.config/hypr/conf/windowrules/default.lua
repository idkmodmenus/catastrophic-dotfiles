hl.window_rule({
    name = "render-unfocused",
    match = { class = "^(firefox|discord|vesktop|[Ss]potify|obs|com\\.obsproject\\.Studio|mpv|steam_app_[0-9]+)$" },
    render_unfocused = true,
})
