-- Apps installed by Catastrophic OS (dock, power menu, walker, ...) live in
-- ~/.local/bin. A display-manager login does not put it on PATH, only shell
-- startup files do, so add it for everything Hyprland launches.
local home = os.getenv("HOME")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
local wanted = ""
for _, dir in ipairs({ home .. "/.local/bin", home .. "/.cargo/bin" }) do
    if not (":" .. path .. ":"):find(":" .. dir .. ":", 1, true) then
        wanted = wanted .. dir .. ":"
    end
end
if wanted ~= "" then
    hl.env("PATH", wanted .. path)
end

-- Quickshell resolves app icons through Qt's icon theme, which does not follow
-- the GTK setting on its own — QS_ICON_THEME is what it reads. Take the name
-- from the GTK settings so the dock and the other shells use the selected icon
-- theme. Read once at compositor start; a theme switch applies on next login.
local gtk_settings = os.getenv("HOME") .. "/.config/gtk-3.0/settings.ini"
local settings = io.open(gtk_settings, "r")
if settings then
    for line in settings:lines() do
        local theme = line:match("^%s*gtk%-icon%-theme%-name%s*=%s*(.-)%s*$")
        if theme and theme ~= "" then
            hl.env("QS_ICON_THEME", theme)
            break
        end
    end
    settings:close()
end

-- Environment variant for this computer, chosen by catastrophic-hypr-tune: "default",
-- "nvidia" (NVIDIA is the only GPU) or "kvm" (virtual machine). Anything unknown or
-- broken falls back to the default, so a bad value can never stop the session.
local variant = machine.environment
if type(variant) ~= "string" or not variant:match("^[%w_-]+$") then variant = "default" end
if not pcall(load_variant, variant .. ".lua", "environments") then
    load_variant("default.lua", "environments")
end

-- The GPU choice for hybrid laptops is NOT made here: Hyprland opens its GPUs before this file
-- runs, so it has to be in the environment before the session starts. catastrophic-hypr-tune
-- puts it in ~/.config/uwsm/env-hyprland.d/ for that (see `catastrophic-hypr-tune --help`).
