require("functions")

require("monitors")
require("conf.monitor")

require("input")

require("gestures")

require("conf.autostart")

require("colors")

require("conf.environment")
require("conf.window")
require("conf.decoration")
require("conf.layout")
require("conf.workspace")
require("conf.misc")
require("conf.keybinding")
require("conf.windowrule")
require("conf.animation")
require("conf.catastrophic")

local f = io.open(os.getenv("HOME") .. "/.config/hypr/custom.lua", "r")
if f then
    f:close()
    require("custom")
end

require("hyprland-gui")

local gamemode = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/catastrophic-gamemode/active", "r")
if gamemode then
    gamemode:close()
    activate_gamemode()
end
