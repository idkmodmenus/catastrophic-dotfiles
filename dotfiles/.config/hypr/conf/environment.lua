local home = os.getenv("HOME")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
local seen, parts = {}, {}
for _, dir in ipairs({ home .. "/.local/bin", home .. "/.cargo/bin" }) do
    seen[dir] = true
    parts[#parts + 1] = dir
end
for dir in path:gmatch("[^:]+") do
    local key = dir:gsub("/+$", "")
    if not seen[key] then
        seen[key] = true
        parts[#parts + 1] = dir
    end
end
hl.env("PATH", table.concat(parts, ":"))

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

local name = "default.lua"
load_variant(name,"environments")
