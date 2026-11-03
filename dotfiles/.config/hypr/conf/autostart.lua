hl.on("hyprland.start", function ()
    local HOME = os.getenv("HOME")

    local wallpaper_app = "quickshell"
    local f = io.open(HOME .. "/.config/catastrophic/settings/wallpaper-app", "r")
    if f then
        wallpaper_app = f:read("*l"):match("^%s*(.-)%s*$")
        f:close()
    end

    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP; " ..
        "systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland; " ..
        "systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal"
    )

    hl.exec_cmd("awww-daemon")

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

    hl.exec_cmd("~/.config/catastrophic/listeners.sh --startall")

    hl.exec_cmd("systemctl --user start hyprpolkitagent.service 2>/dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || true")

    if wallpaper_app ~= "quickshell" then
        hl.exec_cmd("~/.config/catastrophic/scripts/catastrophic-wallpaper-app --restore")
    end

    hl.exec_cmd(
        "d=\"$HOME/.local/state/catastrophic-os-hyprland\"; mkdir -p \"$d\"; " ..
        "ls -1r \"$d\"/catastrophic-autostart-*.log 2>/dev/null | tail -n +10 | xargs -r rm -f; " ..
        "~/.config/catastrophic/scripts/catastrophic-autostart > \"$d/catastrophic-autostart-$(date +%Y-%m-%d_%H-%M-%S).log\" 2>&1"
    )

    hl.exec_cmd("~/.config/hypr/scripts/gtk.sh")

    hl.exec_cmd("hypridle")

    hl.exec_cmd("wl-paste --watch cliphist store")

    hl.exec_cmd("~/.config/hypr/scripts/cleanup.sh")
end)
