pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var defaultSettings: ({
        "powermenu": { "order": ["lock", "suspend", "logout", "reboot", "poweroff"],
                       "marginRight": 0,
                       "editorCommand": "~/.config/catastrophic/settings/editor.sh" },
        "commands":  { "lock":     "~/.config/catastrophic/scripts/catastrophic-power -l",
                       "suspend":  "~/.config/catastrophic/scripts/catastrophic-power -s",
                       "logout":   "~/.config/catastrophic/scripts/catastrophic-power -e",
                       "reboot":   "~/.config/catastrophic/scripts/catastrophic-power -r",
                       "poweroff": "~/.config/catastrophic/scripts/catastrophic-power -p" },
        "button":    { "size": 50, "iconSize": 22, "spacing": 20, "borderWidth": 1 },
        "pill":      { "radius": 40, "paddingX": 15, "paddingY": 20,
                       "animationDuration": 350 },
        "border":    { "width": 2, "colorTop": "", "colorBottom": "" },
        "opacity":   { "normal": 0.9 },
        "theme":     { "colorsFile": "~/.config/catastrophic-powermenu/colors.json" }
    })

    readonly property var buttonIcons: ({
        "lock": "icons/lock.svg",
        "suspend": "icons/suspend.svg",
        "logout": "icons/logout.svg",
        "reboot": "icons/reboot.svg",
        "poweroff": "icons/power.svg"
    })

    property var settings: defaultSettings

    readonly property var buttons: {
        let order = settings.powermenu.order
        if (!Array.isArray(order))
            return []
        return order.filter(function(id) {
            if (root.buttonIcons[id] !== undefined)
                return true
            console.warn("power menu settings: unknown button \"" + id
                + "\" in powermenu.order, skipping it")
            return false
        })
    }

    property bool ready: false

    property bool seeded: false

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/catastrophic-powermenu/config.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: settingsFile.reload()
        onLoaded: { root.applySettings(); root.ready = true }
        onLoadFailed: {
            if (!root.seeded) {
                root.seeded = true
                Qt.callLater(function() { seedProc.running = true })
                return
            }
            root.applySettings()
            root.ready = true
        }
    }

    Process {
        id: seedProc
        command: ["bash", "-c",
            'd="$HOME/.config/catastrophic-powermenu"; f="$d/config.json";'
            + ' mkdir -p "$d" || exit 1;'
            + ' [ -f "$f" ] && exit 0;'
            + ' printf "{\\n}\\n" > "$f"']
        onExited: settingsFile.reload()
    }

    function reloadSettings(): void {
        settingsFile.reload()
        console.log("Power menu reload: re-reading power menu settings")
        applySettings()
    }

    function parseSettings(src) {
        if (!src)
            return undefined
        let raw = src.replace(/\/\*[\s\S]*?\*\//g, "")
        if (raw.trim() === "")
            return undefined
        try {
            return JSON.parse(raw)
        } catch (e) {
            try {
                return JSON.parse(raw.replace(/,(\s*[}\]])/g, "$1"))
            } catch (e2) {
                console.warn("power menu settings: could not parse the settings"
                    + " file, ignoring it:", e2)
                return undefined
            }
        }
    }

    function mergeSettings(merged, src): void {
        let parsed = parseSettings(src)
        if (parsed === undefined)
            return
        for (let group in parsed)
            for (let key in parsed[group])
                if (merged[group] !== undefined)
                    merged[group][key] = parsed[group][key]
    }

    function applySettings(): void {
        let merged = JSON.parse(JSON.stringify(root.defaultSettings))
        mergeSettings(merged, settingsFile.text())
        root.settings = merged
    }

    function runCommand(id): void {
        let cmd = root.settings.commands[id]
        if (typeof cmd !== "string" || cmd.trim() === "") {
            console.warn("power menu: no command configured for \"" + id + "\"")
            return
        }
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function editConfig(): void {
        Quickshell.execDetached(["bash", "-c",
            'f="$HOME/.config/catastrophic-powermenu/config.json"; c="${1/#\\~/$HOME}";'
            + ' if [ -n "$c" ] && command -v "${c%% *}" >/dev/null 2>&1;'
            + ' then eval "$c \\"\\$f\\""; else exec xdg-open "$f"; fi',
            "powermenu-edit", root.settings.powermenu.editorCommand || ""])
    }
}
