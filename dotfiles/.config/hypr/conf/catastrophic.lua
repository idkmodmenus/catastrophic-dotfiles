--    __  _____  _____      __  _____          ___
--   /  |/  / / / / / | /| / / / ___/__  ___  / _/
--  / /|_/ / /_/_  _/ |/ |/ / / /__/ _ \/ _ \/ _/
-- /_/  /_/____//_/ |__/|__/  \___/\___/_//_/_/
--

-- PATH (~/.local/bin and ~/.cargo/bin) is set once, in environment.lua

-- Pavucontrol
hl.window_rule({
    name = "pavucontrol",
    match = {class = ".*org.pulseaudio.pavucontrol.*"},
    float = true,
    center = true,
    size = "700 600"
})

-- Catastrophic Welcome App
hl.window_rule({
    name = "catastrophic-welcome-app",
    match = {title = "Catastrophic Welcome"},
    float = true,
    center = true,
    pin = true,
    size = "700 600"
})

-- Catastrophic Dock Settings (Quickshell dock dialog)
hl.window_rule({
    name = "catastrophic-dock-settings",
    match = {title = "Catastrophic Dock Settings"},
    float = true,
    center = true,
    pin = true,
    size = "480 300"
})

-- Catastrophic Settings App
hl.window_rule({
    name = "catastrophic-settings-app",
    match = {title = "Catastrophic Dotfiles Settings"},
    float = true,
    center = true,
    pin = true,
    size = "900 600"
})

-- Newelle
hl.window_rule({
    name = "newelle",
    match = {class = "io.github.qwersyk.Newelle"},
    float = true,
    center = true,
    pin = true,
    size = "1000 700"
})

-- Blueman Manager
hl.window_rule({
    name = "blueman-manager",
    match = {class = "blueman-manager"},
    float = true,
    center = true,
    size = "800 600"
})

-- nwg-look
hl.window_rule({
    name = "nwg-look",
    match = {class = "nwg-look"},
    float = true,
    center = true,
    size = "700 600"
})

-- nwg-displays
hl.window_rule({
    name = "nwg-displays",
    match = {class = "nwg-displays"},
    float = true,
    center = true,
    size = "900 600"
})

-- System Mission Center
hl.window_rule({
    name = "missioncenter",
    match = {class = "io.missioncenter.MissionCenter"},
    float = true,
    center = true,
    pin = true,
    size = "900 600"
})

-- Gnome Calculator
hl.window_rule({
    name = "gnome-calculator",
    match = {class = "org.gnome.Calculator"},
    float = true,
    center = true,
    size = "700 600"
})

-- Hyprland Share Picker
hl.window_rule({
    name = "hyprland-share-picker",
    match = {class = "hyprland-share-picker"},
    float = true,
    pin = true,
    center = true,
    size = "600 400"
})

-- GTK File and Folder Picker
hl.window_rule({
    name = "xdg-desktop-portal-gtk",
    match = {class = "xdg-desktop-portal-gtk"},
    float = true,
    center = false,
    size = "800 600"
})

-- nm-connection-editor
hl.window_rule({
    name = "nm-connection-editor",
    match = {class = "nm-connection-editor"},
    float = true,
    center = true,
    size = "800 700"
})

-- Hyprmod
hl.window_rule({
    name = "io.github.bluemancz.hyprmod",
    match = {class = "io.github.bluemancz.hyprmod"},
    float = true,
    center = true,
    size = "1000 700"
})

-- Catastrophic Floating
hl.window_rule({
    name = "dotfiles-floating",
    match = {class = "dotfiles-floating"},
    float = true,
    center = true,
    size = "1000 700"
})

-- Picture-in-Picture
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

-- XWayland Video Bridge
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

-- Wayland variables
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("DESKTOP_SESSION", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Qt related environment variables
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- GDK
hl.env("GDK_SCALE", "1")

-- Toolkit Backend
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")

-- Mozilla
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Set the cursor size for xcursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- SDL: the video driver is not forced to wayland. SDL picks wayland by itself where it can,
-- and forcing it breaks SDL games that run through XWayland (Steam/Proton).

-- Quickshell debug
hl.env("QS_NO_RELOAD_POPUP", "1")

-- Force zero scaling for XWayland
hl.config({
  xwayland = {
    force_zero_scaling = true
  }
})