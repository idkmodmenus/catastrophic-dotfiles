local HOME = os.getenv("HOME")

local current_path = os.getenv("PATH")
hl.env("PATH", HOME .. "/.local/bin:" .. current_path)

local current_path = os.getenv("PATH")
hl.env("PATH", HOME .. "/.cargo/bin:" .. current_path)

hl.window_rule({
    name = "pavucontrol",
    match = {class = ".*org.pulseaudio.pavucontrol.*"},
    float = true,
    center = true,
    size = "700 600"
})

hl.window_rule({
    name = "catastrophic-welcome-app",
    match = {title = "Catastrophic Welcome"},
    float = true,
    center = true,
    pin = true,
    size = "940 640"
})

hl.window_rule({
    name = "catastrophic-dock-settings",
    match = {title = "Catastrophic Dock Settings"},
    float = true,
    center = true,
    pin = true,
    size = "480 300"
})

hl.window_rule({
    name = "catastrophic-settings-app",
    match = {title = "Catastrophic Dotfiles Settings"},
    float = true,
    center = true,
    pin = true,
    size = "900 600"
})

hl.window_rule({
    name = "newelle",
    match = {class = "io.github.qwersyk.Newelle"},
    float = true,
    center = true,
    pin = true,
    size = "1000 700"
})

hl.window_rule({
    name = "blueman-manager",
    match = {class = "blueman-manager"},
    float = true,
    center = true,
    size = "800 600"
})

hl.window_rule({
    name = "nwg-look",
    match = {class = "nwg-look"},
    float = true,
    center = true,
    size = "700 600"
})

hl.window_rule({
    name = "nwg-displays",
    match = {class = "nwg-displays"},
    float = true,
    center = true,
    size = "900 600"
})

hl.window_rule({
    name = "missioncenter",
    match = {class = "io.missioncenter.MissionCenter"},
    float = true,
    center = true,
    pin = true,
    size = "900 600"
})

hl.window_rule({
    name = "gnome-calculator",
    match = {class = "org.gnome.Calculator"},
    float = true,
    center = true,
    size = "700 600"
})

hl.window_rule({
    name = "hyprland-share-picker",
    match = {class = "hyprland-share-picker"},
    float = true,
    pin = true,
    center = true,
    size = "600 400"
})

hl.window_rule({
    name = "xdg-desktop-portal-gtk",
    match = {class = "xdg-desktop-portal-gtk"},
    float = true,
    center = false,
    size = "800 600"
})

hl.window_rule({
    name = "nm-connection-editor",
    match = {class = "nm-connection-editor"},
    float = true,
    center = true,
    size = "800 700"
})

hl.window_rule({
    name = "io.github.bluemancz.hyprmod",
    match = {class = "io.github.bluemancz.hyprmod"},
    float = true,
    center = true,
    size = "1000 700"
})

hl.window_rule({
    name = "dotfiles-floating",
    match = {class = "dotfiles-floating"},
    float = true,
    center = true,
    size = "1000 700"
})

hl.window_rule({
    name = "Picture-in-Picture",
    match = {
        title = [[^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$]]
    },
    float = true,
    pin = true,
    focus_on_activate = false,
    no_initial_focus = true,
    suppress_event = "activate"
})

hl.window_rule({
    name = "catastrophic-dropdown",
    match = { class = "^(catastrophic-dropdown)$" },
    float = true,
    size = "(monitor_w*0.6) (monitor_h*0.45)",
    move = "(monitor_w*0.2) 58",
    workspace = "special:dropdown silent"
})

hl.layer_rule({
    name = "catastrophic-drawers",
    match = { namespace = "^(frame-drawer)$" },
    no_anim = true
})

hl.layer_rule({
    name = "catastrophic-glass",
    match = { namespace = "^(frame|frame-drawer|catastrophic-dock)$" },
    blur = true,
    ignore_alpha = 0.05
})

hl.window_rule({
    name = "xwaylandvideobridge",
    match = { class = "^(xwaylandvideobridge)$" },
    opacity = "0.0 override 0.0 override",
    no_anim = true,
    no_initial_focus = true,
    max_size = "1 1",
    no_blur = true,
    float = true
})

hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("DESKTOP_SESSION", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("GDK_SCALE", "1")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("SDL_VIDEODRIVER", "wayland")

hl.env("QS_NO_RELOAD_POPUP", "1")

hl.config({
  xwayland = {
    force_zero_scaling = true
  }
})