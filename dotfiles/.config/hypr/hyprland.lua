--    __  _____  _____      __  ____  ____
--   /  |/  / / / / / | /| / / / __ \/ __/
--  / /|_/ / /_/_  _/ |/ |/ / / /_/ /\ \  
-- /_/  /_/____//_/ |__/|__/  \____/___/
--   
-- Advanced configuration for Hyprland

-- FUNCTIONS
require("functions")

-- THIS MACHINE
-- machine.lua is written by catastrophic-hypr-tune (run by the installer, and by hand with
-- `catastrophic-hypr-tune`). It holds what depends on the hardware: the GPU setup and the
-- environment variant. It is not part of the repository, so updates never overwrite it, and
-- a missing or broken file simply means defaults. Put your own changes in custom.lua instead.
local machine_ok, machine = pcall(require, "machine")
if not machine_ok then
    if not tostring(machine):find("module 'machine' not found", 1, true) then
        print("catastrophic: machine.lua ignored: " .. tostring(machine))
    end
    machine = nil
end
if type(machine) ~= "table" then machine = {} end
_G.machine = machine

-- MONITORS
-- monitors.lua is written by nwg-displays. Without it (or if it is broken) every monitor
-- is used at its preferred mode, so a missing file can never leave the session without a screen.
if not pcall(require, "monitors") then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end
require("conf.monitor")

-- INPUT
require("input")

-- GESTURE
require("gestures")

-- AUTOSTART
require("conf.autostart")

-- COLORS
require("colors")

-- CONFIGURATION
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

-- CUSTOM
local f = io.open(os.getenv("HOME") .. "/.config/hypr/custom.lua", "r")
if f then
    f:close()
    require("custom")
end

-- HYPRMOD
require("hyprland-gui")
